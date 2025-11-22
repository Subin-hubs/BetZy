import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FFCreatePage extends StatefulWidget {
  const FFCreatePage({super.key});

  @override
  State<FFCreatePage> createState() => _FFCreatePageState();
}

class _FFCreatePageState extends State<FFCreatePage> {
  // Dropdown selections
  String? selectedMode;
  String? selectedTeamSize;
  String? selectedGunAttributes;
  String? selectedUnlimitedItems;
  String? selectedCharacterSkills;

  // Textfield controller for points
  TextEditingController pointsController = TextEditingController();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading state
  bool _isCreating = false;

  // Colors
  final Color primaryColor = const Color(0xFF2962FF);
  final Color accentColor = const Color(0xFFFF6B35);

  // Dropdown options
  final List<String> modes = [
    "Clash Squad",
    "Lone Wolf",
    "Full Map",
  ];

  @override
  void dispose() {
    pointsController.dispose();
    super.dispose();
  }

  // Get team size options based on selected mode
  List<String> get teamSizeOptions {
    if (selectedMode == "Clash Squad") {
      return ["1v1", "4v4"];
    } else if (selectedMode == "Lone Wolf") {
      return ["1v1", "2v2"];
    }
    return [];
  }

  // Check if team size should be shown
  bool get shouldShowTeamSize {
    return selectedMode == "Clash Squad" || selectedMode == "Lone Wolf";
  }

  Future<void> _createMatch() async {
    // Validation
    if (selectedMode == null) {
      _showError("Please select a mode");
      return;
    }
    if (shouldShowTeamSize && selectedTeamSize == null) {
      _showError("Please select team size");
      return;
    }
    if (selectedGunAttributes == null) {
      _showError("Please select Gun Attributes");
      return;
    }
    if (selectedUnlimitedItems == null) {
      _showError("Please select Unlimited Items");
      return;
    }
    if (selectedCharacterSkills == null) {
      _showError("Please select Character Skills");
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
        'mode': selectedMode,
        'teamSize': selectedTeamSize ?? 'N/A',
        'gunAttributes': selectedGunAttributes,
        'unlimitedItems': selectedUnlimitedItems,
        'characterSkills': selectedCharacterSkills,
        'points': int.parse(pointsController.text.trim()),
        'createdBy': {
          'userId': currentUser.uid,
          'userName': userName,
          'userEmail': currentUser.email,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active', // active, completed, cancelled
      };

      // Save to Firebase
      DocumentReference matchRef = await _firestore
          .collection('matches')
          .add(matchData);

      if (mounted) {
        // Success
        Fluttertoast.showToast(
          msg: "🎮 Match Created Successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Clear form
        setState(() {
          selectedMode = null;
          selectedTeamSize = null;
          selectedGunAttributes = null;
          selectedUnlimitedItems = null;
          selectedCharacterSkills = null;
          pointsController.clear();
        });

        // Optional: Show match ID
        print('Match created with ID: ${matchRef.id}');
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
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Create Match",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Match Setup",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Configure your game settings",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mode Selection Card
            _buildCard(
              title: "Game Mode",
              icon: Icons.gamepad,
              child: _buildDropdown(
                value: selectedMode,
                hint: "Select Mode",
                items: modes,
                onChanged: (v) {
                  setState(() {
                    selectedMode = v;
                    selectedTeamSize = null;
                  });
                },
              ),
            ),

            // Team Size Card (Conditional)
            if (shouldShowTeamSize) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: "Team Size",
                icon: Icons.groups,
                child: Row(
                  children: teamSizeOptions.map((size) {
                    final index = teamSizeOptions.indexOf(size);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < teamSizeOptions.length - 1 ? 12 : 0,
                        ),
                        child: _buildTeamSizeOption(size),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Gun Attributes Card
            _buildCard(
              title: "Gun Attributes",
              icon: Icons.gps_fixed,
              child: _buildYesNoButtons(
                value: selectedGunAttributes,
                onChanged: (v) => setState(() => selectedGunAttributes = v),
              ),
            ),

            const SizedBox(height: 16),

            // Unlimited Items Card
            _buildCard(
              title: "Unlimited Items",
              icon: Icons.inventory_2_outlined,
              child: _buildYesNoButtons(
                value: selectedUnlimitedItems,
                onChanged: (v) => setState(() => selectedUnlimitedItems = v),
              ),
            ),

            const SizedBox(height: 16),

            // Character Skills Card
            _buildCard(
              title: "Character Skills",
              icon: Icons.auto_awesome,
              child: _buildYesNoButtons(
                value: selectedCharacterSkills,
                onChanged: (v) => setState(() => selectedCharacterSkills = v),
              ),
            ),

            const SizedBox(height: 16),

            // Points Card
            _buildCard(
              title: "Match Points",
              icon: Icons.stars_rounded,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter points (e.g. 50, 100)",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(
                      Icons.monetization_on,
                      color: accentColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 24),
                    SizedBox(width: 10),
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
    );
  }

  // Card Wrapper with Icon
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
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
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // Dropdown
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey.shade500),
        ),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Team Size Option
  Widget _buildTeamSizeOption(String size) {
    final isSelected = selectedTeamSize == size;
    IconData icon = size == "1v1" ? Icons.person : Icons.groups;

    return GestureDetector(
      onTap: () => setState(() => selectedTeamSize = size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              size,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yes/No Buttons
  Widget _buildYesNoButtons({
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildYesNoOption(
            label: "Yes",
            icon: Icons.check_circle,
            isSelected: value == "Yes",
            onTap: () => onChanged("Yes"),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildYesNoOption(
            label: "No",
            icon: Icons.cancel,
            isSelected: value == "No",
            onTap: () => onChanged("No"),
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildYesNoOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}