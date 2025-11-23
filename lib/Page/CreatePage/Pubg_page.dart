import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PUBGCreatePage extends StatefulWidget {
  const PUBGCreatePage({super.key});

  @override
  State<PUBGCreatePage> createState() => _PUBGCreatePageState();
}

class _PUBGCreatePageState extends State<PUBGCreatePage> with SingleTickerProviderStateMixin {
  // Dropdown selections
  String? selectedMode;
  String? selectedMap;
  String? selectedTeamSize;
  String? selectedPerspective;
  String? selectedWeatherMode;
  String? selectedZoneMode;

  // Textfield controller for points
  TextEditingController pointsController = TextEditingController();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading state
  bool _isCreating = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dropdown options
  final List<String> modes = [
    "Classic",
    "Arena",
    "TDM",
  ];

  final Map<String, List<String>> mapsByMode = {
    "Classic": ["Erangel", "Miramar", "Sanhok", "Vikendi", "Livik", "Karakin"],
    "Arena": ["Arena Training", "Warehouse", "Ruins"],
    "TDM": ["Hangar", "Library", "Town"],
  };

  final List<String> perspectives = ["TPP", "FPP"];
  final List<String> weatherModes = ["Clear", "Sunset", "Overcast", "Rain"];
  final List<String> zoneModes = ["Normal", "Fast"];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    pointsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get team size options based on selected mode
  List<String> get teamSizeOptions {
    if (selectedMode == "Classic") {
      return ["Solo", "Duo", "Squad"];
    } else if (selectedMode == "Arena" || selectedMode == "TDM") {
      return ["4v4", "8v8"];
    }
    return [];
  }

  // Get available maps for selected mode
  List<String> get availableMaps {
    if (selectedMode == null) return [];
    return mapsByMode[selectedMode] ?? [];
  }

  Future<void> _createMatch() async {
    // Validation
    if (selectedMode == null) {
      _showError("Please select a mode");
      return;
    }
    if (selectedMap == null) {
      _showError("Please select a map");
      return;
    }
    if (selectedTeamSize == null) {
      _showError("Please select team size");
      return;
    }
    if (selectedPerspective == null) {
      _showError("Please select perspective");
      return;
    }
    if (selectedMode == "Classic" && selectedWeatherMode == null) {
      _showError("Please select weather mode");
      return;
    }
    if (selectedMode == "Classic" && selectedZoneMode == null) {
      _showError("Please select zone mode");
      return;
    }
    if (pointsController.text.trim().isEmpty) {
      _showError("Please enter points");
      return;
    }

    // Get current user
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showError("You must be logged in to create a match");
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Get user details from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String userName = userDoc.exists && userDoc['name'] != null
          ? userDoc['name']
          : currentUser.displayName ?? 'Unknown User';

      // Prepare match data
      Map<String, dynamic> matchData = {
        'game': 'PUBG',
        'mode': selectedMode,
        'map': selectedMap,
        'teamSize': selectedTeamSize,
        'perspective': selectedPerspective,
        'weatherMode': selectedWeatherMode ?? 'N/A',
        'zoneMode': selectedZoneMode ?? 'N/A',
        'points': int.parse(pointsController.text.trim()),
        'participants': [],
        'createdBy': {
          'userId': currentUser.uid,
          'userName': userName,
          'userEmail': currentUser.email,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      // Save to Firebase
      await _firestore.collection('matches').add(matchData);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "🎯 PUBG Match Created!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          textColor: Colors.white,
          fontSize: 15.0,
        );

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Match Created!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your $selectedMode match on $selectedMap is now live!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "View All Matches",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Clear form
        setState(() {
          selectedMode = null;
          selectedMap = null;
          selectedTeamSize = null;
          selectedPerspective = null;
          selectedWeatherMode = null;
          selectedZoneMode = null;
          pointsController.clear();
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showError('Firebase Error: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error creating match: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFFEF4444),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Create PUBG Match",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "🎯",
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PUBG Mobile",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Configure your custom room",
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

              const SizedBox(height: 28),

              // Mode Selection
              _buildCard(
                title: "Game Mode",
                icon: Icons.gamepad_rounded,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: modes.map((mode) {
                    return _buildModeChip(mode);
                  }).toList(),
                ),
              ),

              // Map Selection
              if (selectedMode != null && availableMaps.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCard(
                  title: "Select Map",
                  icon: Icons.map_rounded,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableMaps.map((map) {
                      return _buildMapChip(map);
                    }).toList(),
                  ),
                ),
              ],

              // Team Size
              if (selectedMode != null && teamSizeOptions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCard(
                  title: "Team Size",
                  icon: Icons.groups_rounded,
                  child: Row(
                    children: teamSizeOptions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final size = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < teamSizeOptions.length - 1 ? 10 : 0,
                          ),
                          child: _buildTeamSizeOption(size),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Perspective
              _buildCard(
                title: "Perspective",
                icon: Icons.remove_red_eye_rounded,
                child: Row(
                  children: perspectives.asMap().entries.map((entry) {
                    final index = entry.key;
                    final perspective = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < perspectives.length - 1 ? 10 : 0,
                        ),
                        child: _buildPerspectiveOption(perspective),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Weather Mode (only for Classic)
              if (selectedMode == "Classic") ...[
                const SizedBox(height: 16),
                _buildCard(
                  title: "Weather Mode",
                  icon: Icons.wb_sunny_rounded,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: weatherModes.map((weather) {
                      return _buildWeatherChip(weather);
                    }).toList(),
                  ),
                ),
              ],

              // Zone Mode (only for Classic)
              if (selectedMode == "Classic") ...[
                const SizedBox(height: 16),
                _buildCard(
                  title: "Zone Mode",
                  icon: Icons.speed_rounded,
                  child: Row(
                    children: zoneModes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final zone = entry.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < zoneModes.length - 1 ? 10 : 0,
                          ),
                          child: _buildZoneOption(zone),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Points
              _buildCard(
                title: "Match Points",
                icon: Icons.stars_rounded,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
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
                      hintText: "Enter points (e.g. 50, 100)",
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFF59E0B),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create Button
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isCreating ? null : _createMatch,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isCreating
                          ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Create Match",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFF59E0B),
                  size: 22,
                ),
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
    final isSelected = selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          selectedMode = mode;
          selectedMap = null;
          selectedTeamSize = null;
          selectedWeatherMode = null;
          selectedZoneMode = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMapChip(String map) {
    final isSelected = selectedMap == map;
    return InkWell(
      onTap: () => setState(() => selectedMap = map),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_rounded,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              map,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSizeOption(String size) {
    final isSelected = selectedTeamSize == size;
    IconData icon;

    if (size == "Solo") {
      icon = Icons.person_rounded;
    } else if (size == "Duo") {
      icon = Icons.people_rounded;
    } else if (size == "Squad" || size == "4v4") {
      icon = Icons.groups_rounded;
    } else {
      icon = Icons.groups_3_rounded;
    }

    return InkWell(
      onTap: () => setState(() => selectedTeamSize = size),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              size,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerspectiveOption(String perspective) {
    final isSelected = selectedPerspective == perspective;
    IconData icon = perspective == "TPP"
        ? Icons.person_outline_rounded
        : Icons.remove_red_eye_outlined;

    return InkWell(
      onTap: () => setState(() => selectedPerspective = perspective),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              perspective,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherChip(String weather) {
    final isSelected = selectedWeatherMode == weather;
    IconData icon;

    switch (weather) {
      case "Clear":
        icon = Icons.wb_sunny_rounded;
        break;
      case "Sunset":
        icon = Icons.wb_twilight_rounded;
        break;
      case "Overcast":
        icon = Icons.cloud_rounded;
        break;
      case "Rain":
        icon = Icons.water_drop_rounded;
        break;
      default:
        icon = Icons.wb_sunny_rounded;
    }

    return InkWell(
      onTap: () => setState(() => selectedWeatherMode = weather),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              weather,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneOption(String zone) {
    final isSelected = selectedZoneMode == zone;
    IconData icon = zone == "Normal"
        ? Icons.speed_rounded
        : Icons.bolt_rounded;

    return InkWell(
      onTap: () => setState(() => selectedZoneMode = zone),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC4899) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFEC4899) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              zone,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}