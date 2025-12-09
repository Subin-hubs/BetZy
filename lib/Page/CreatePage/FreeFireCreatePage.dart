import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FFCreatePage extends StatefulWidget {
  const FFCreatePage({super.key});

  @override
  State<FFCreatePage> createState() => _FFCreatePageState();
}

class _FFCreatePageState extends State<FFCreatePage>
    with SingleTickerProviderStateMixin {
  String? selectedMode;
  String? selectedMap;
  String? selectedTeamSize;
  String? selectedGunAttributes;
  String? selectedUnlimitedItems;
  String? selectedCharacterSkills;
  TextEditingController pointsController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCreating = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> modes = [
    "Clash Squad",
    "Lone Wolf",
    "Battle Royale",
  ];

  final Map<String, List<String>> mapsByMode = {
    "Clash Squad": ["CS Academy", "Peak", "Mill", "Brasilia"],
    "Lone Wolf": ["Lone Wolf Arena"],
    "Battle Royale": ["Bermuda", "Purgatory", "Kalahari", "Alpine", "Nexterra"],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    pointsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<String> get teamSizeOptions {
    if (selectedMode == "Clash Squad") return ["1v1", "2v2", "4v4"];
    if (selectedMode == "Lone Wolf") return ["1v1", "2v2"];
    if (selectedMode == "Battle Royale") return ["Solo", "Duo", "Squad"];
    return [];
  }

  List<String> get availableMaps {
    if (selectedMode == null) return [];
    return mapsByMode[selectedMode] ?? [];
  }

  Future<void> _createMatch() async {
    if (selectedMode == null) return _showError("Please select a mode");
    if (selectedMap == null) return _showError("Please select a map");
    if (selectedTeamSize == null) return _showError("Please select team size");
    if (selectedGunAttributes == null) return _showError("Please select Gun Attributes");
    if (selectedUnlimitedItems == null) return _showError("Please select Unlimited Items");
    if (selectedCharacterSkills == null) return _showError("Please select Character Skills");
    if (pointsController.text.trim().isEmpty) {
      return _showError("Please enter points");
    }

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return _showError("You must be logged in to create a match");

    int matchPoints = int.tryParse(pointsController.text.trim()) ?? 0;
    if (matchPoints <= 0) return _showError("Please enter a valid point amount");

    setState(() => _isCreating = true);

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        _showError("User profile not found");
        setState(() => _isCreating = false);
        return;
      }

      String userName = userDoc['name'] ?? currentUser.displayName ?? "Unknown User";
      int currentPoints = (userDoc['points'] as num).toInt();

      if (currentPoints < matchPoints) {
        _showError("Insufficient points! You have $currentPoints but need $matchPoints.");
        setState(() => _isCreating = false);
        return;
      }

      int newPoints = currentPoints - matchPoints;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'points': newPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      Map<String, dynamic> matchData = {
        'game': 'Free Fire',
        'mode': selectedMode,
        'map': selectedMap,
        'teamSize': selectedTeamSize,
        'gunAttributes': selectedGunAttributes,
        'unlimitedItems': selectedUnlimitedItems,
        'characterSkills': selectedCharacterSkills,
        'points': matchPoints,
        'participants': [],
        'createdBy': {
          'userId': currentUser.uid,
          'userName': userName,
          'userEmail': currentUser.email,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await _firestore.collection('matches').add(matchData);

      Fluttertoast.showToast(
        msg: "🎯 Match Created! $matchPoints points deducted.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.white,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Match Created!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "$matchPoints points deducted",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  "Remaining: $newPoints points",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      setState(() {
        selectedMode = null;
        selectedMap = null;
        selectedTeamSize = null;
        selectedGunAttributes = null;
        selectedUnlimitedItems = null;
        selectedCharacterSkills = null;
        pointsController.clear();
      });
    } catch (e) {
      _showError("Error creating match: $e");
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: const Color(0xFFEF4444),
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Create Match",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Animated Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "🔥",
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Free Fire",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Create your custom match",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Game Mode Selection
              _buildCard(
                title: "Game Mode",
                icon: Icons.sports_esports_rounded,
                iconColor: const Color(0xFF8B5CF6),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: modes.map((m) => _buildModeChip(m)).toList(),
                ),
              ),

              // Map Selection (conditional)
              if (selectedMode != null) ...[
                const SizedBox(height: 16),
                _buildCard(
                  title: "Select Map",
                  icon: Icons.map_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableMaps.map((m) => _buildMapChip(m)).toList(),
                  ),
                ),
              ],

              // Team Size (conditional)
              if (selectedMode != null) ...[
                const SizedBox(height: 16),
                _buildCard(
                  title: "Team Size",
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFFEC4899),
                  child: Row(
                    children: teamSizeOptions
                        .map((size) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildTeamSizeOption(size),
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Settings Cards
              _buildCard(
                title: "Gun Attributes",
                icon: Icons.gps_fixed_rounded,
                iconColor: const Color(0xFFF59E0B),
                child: _buildYesNoButtons(
                  value: selectedGunAttributes,
                  onChanged: (v) => setState(() => selectedGunAttributes = v),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                title: "Unlimited Items",
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xFF10B981),
                child: _buildYesNoButtons(
                  value: selectedUnlimitedItems,
                  onChanged: (v) => setState(() => selectedUnlimitedItems = v),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                title: "Character Skills",
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF06B6D4),
                child: _buildYesNoButtons(
                  value: selectedCharacterSkills,
                  onChanged: (v) => setState(() => selectedCharacterSkills = v),
                ),
              ),
              const SizedBox(height: 16),

              // Points Input
              _buildCard(
                title: "Match Points",
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFFFBBF24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    decoration: const InputDecoration(
                      hintText: "Enter points",
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: Icon(Icons.monetization_on, color: Color(0xFFFBBF24)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Create Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "Create Match",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode) {
    bool selected = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = mode;
          selectedMap = null;
          selectedTeamSize = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          )
              : null,
          color: selected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMapChip(String map) {
    bool selected = selectedMap == map;
    return GestureDetector(
      onTap: () => setState(() => selectedMap = map),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          )
              : null,
          color: selected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          map,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSizeOption(String size) {
    bool selected = selectedTeamSize == size;
    return GestureDetector(
      onTap: () => setState(() => selectedTeamSize = size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
          )
              : null,
          color: selected ? null : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              size.contains("1")
                  ? Icons.person
                  : size.contains("2")
                  ? Icons.people
                  : Icons.groups,
              color: selected ? Colors.white : const Color(0xFF6B7280),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              size,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoButtons({
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildYesNoOption(
            label: "Yes",
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            selected: value == "Yes",
            onTap: () => onChanged("Yes"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildYesNoOption(
            label: "No",
            icon: Icons.cancel_rounded,
            color: const Color(0xFFEF4444),
            selected: value == "No",
            onTap: () => onChanged("No"),
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF6B7280),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}