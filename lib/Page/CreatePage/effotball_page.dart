import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EFootballCreatePage extends StatefulWidget {
  const EFootballCreatePage({super.key});

  @override
  State<EFootballCreatePage> createState() => _EFootballCreatePageState();
}

class _EFootballCreatePageState extends State<EFootballCreatePage> with SingleTickerProviderStateMixin {
  // Dropdown selections
  String? selectedMode;
  String? selectedMatchTime;
  String? selectedDifficulty;
  String? selectedStadium;
  String? selectedWeather;
  String? selectedTimeOfDay;

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
    "1v1",
    "2v2",
    "3v3",
  ];

  final List<String> matchTimes = [
    "3 Minutes",
    "5 Minutes",
    "10 Minutes",
    "Full Match",
  ];

  final List<String> difficulties = [
    "Beginner",
    "Amateur",
    "Professional",
    "Legend",
  ];

  final List<String> stadiums = [
    "Camp Nou",
    "Old Trafford",
    "Santiago Bernabéu",
    "Allianz Arena",
    "San Siro",
    "Anfield",
    "Parc des Princes",
    "Stamford Bridge",
  ];

  final List<String> weatherOptions = [
    "Clear",
    "Rainy",
    "Snowy",
    "Cloudy",
  ];

  final List<String> timeOfDayOptions = [
    "Day",
    "Night",
    "Sunset",
  ];

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

  Future<void> _createMatch() async {
    // Validation
    if (selectedMode == null) {
      _showError("Please select a mode");
      return;
    }
    if (selectedMatchTime == null) {
      _showError("Please select match time");
      return;
    }
    if (selectedDifficulty == null) {
      _showError("Please select difficulty");
      return;
    }
    if (selectedStadium == null) {
      _showError("Please select a stadium");
      return;
    }
    if (selectedWeather == null) {
      _showError("Please select weather");
      return;
    }
    if (selectedTimeOfDay == null) {
      _showError("Please select time of day");
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
        'game': 'eFootball',
        'mode': selectedMode,
        'map': selectedStadium, // Using stadium as map
        'matchTime': selectedMatchTime,
        'difficulty': selectedDifficulty,
        'stadium': selectedStadium,
        'weather': selectedWeather,
        'timeOfDay': selectedTimeOfDay,
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
          msg: "⚽ eFootball Match Created!",
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
                  "Your $selectedMode match at $selectedStadium is now live!",
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
                      backgroundColor: const Color(0xFF10B981),
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
          selectedMatchTime = null;
          selectedDifficulty = null;
          selectedStadium = null;
          selectedWeather = null;
          selectedTimeOfDay = null;
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
          "Create eFootball Match",
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
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
                        "⚽",
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "eFootball",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Configure your football match",
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
                title: "Match Mode",
                icon: Icons.groups_rounded,
                child: Row(
                  children: modes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final mode = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < modes.length - 1 ? 10 : 0,
                        ),
                        child: _buildModeOption(mode),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Match Time
              _buildCard(
                title: "Match Duration",
                icon: Icons.timer_rounded,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: matchTimes.map((time) {
                    return _buildTimeChip(time);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Difficulty
              _buildCard(
                title: "Difficulty Level",
                icon: Icons.trending_up_rounded,
                child: Column(
                  children: difficulties.asMap().entries.map((entry) {
                    final difficulty = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < difficulties.length - 1 ? 10 : 0,
                      ),
                      child: _buildDifficultyOption(difficulty),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Stadium Selection
              _buildCard(
                title: "Select Stadium",
                icon: Icons.stadium_rounded,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: stadiums.map((stadium) {
                    return _buildStadiumChip(stadium);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Weather
              _buildCard(
                title: "Weather Conditions",
                icon: Icons.wb_sunny_rounded,
                child: Row(
                  children: weatherOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final weather = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < weatherOptions.length - 1 ? 8 : 0,
                        ),
                        child: _buildWeatherOption(weather),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Time of Day
              _buildCard(
                title: "Time of Day",
                icon: Icons.brightness_6_rounded,
                child: Row(
                  children: timeOfDayOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final timeOfDay = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < timeOfDayOptions.length - 1 ? 10 : 0,
                        ),
                        child: _buildTimeOfDayOption(timeOfDay),
                      ),
                    );
                  }).toList(),
                ),
              ),

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
                        color: Color(0xFF10B981),
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF10B981),
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

  Widget _buildModeOption(String mode) {
    final isSelected = selectedMode == mode;
    IconData icon = mode == "1v1"
        ? Icons.person_rounded
        : mode == "2v2"
        ? Icons.people_rounded
        : Icons.groups_rounded;

    return InkWell(
      onTap: () => setState(() => selectedMode = mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
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
              mode,
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

  Widget _buildTimeChip(String time) {
    final isSelected = selectedMatchTime == time;
    return InkWell(
      onTap: () => setState(() => selectedMatchTime = time),
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
              Icons.timer_rounded,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              time,
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

  Widget _buildDifficultyOption(String difficulty) {
    final isSelected = selectedDifficulty == difficulty;
    Color difficultyColor;
    IconData icon;

    switch (difficulty) {
      case "Beginner":
        difficultyColor = const Color(0xFF10B981);
        icon = Icons.sentiment_satisfied_rounded;
        break;
      case "Amateur":
        difficultyColor = const Color(0xFF3B82F6);
        icon = Icons.sports_esports_rounded;
        break;
      case "Professional":
        difficultyColor = const Color(0xFFF59E0B);
        icon = Icons.trending_up_rounded;
        break;
      case "Legend":
        difficultyColor = const Color(0xFFEF4444);
        icon = Icons.emoji_events_rounded;
        break;
      default:
        difficultyColor = const Color(0xFF10B981);
        icon = Icons.sentiment_satisfied_rounded;
    }

    return InkWell(
      onTap: () => setState(() => selectedDifficulty = difficulty),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? difficultyColor.withOpacity(0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? difficultyColor : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? difficultyColor : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(width: 14),
            Text(
              difficulty,
              style: TextStyle(
                color: isSelected ? difficultyColor : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStadiumChip(String stadium) {
    final isSelected = selectedStadium == stadium;
    return InkWell(
      onTap: () => setState(() => selectedStadium = stadium),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stadium_rounded,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              stadium,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherOption(String weather) {
    final isSelected = selectedWeather == weather;
    IconData icon;

    switch (weather) {
      case "Clear":
        icon = Icons.wb_sunny_rounded;
        break;
      case "Rainy":
        icon = Icons.water_drop_rounded;
        break;
      case "Snowy":
        icon = Icons.ac_unit_rounded;
        break;
      case "Cloudy":
        icon = Icons.cloud_rounded;
        break;
      default:
        icon = Icons.wb_sunny_rounded;
    }

    return InkWell(
      onTap: () => setState(() => selectedWeather = weather),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF06B6D4).withOpacity(0.3),
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
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              weather,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOfDayOption(String timeOfDay) {
    final isSelected = selectedTimeOfDay == timeOfDay;
    IconData icon;

    switch (timeOfDay) {
      case "Day":
        icon = Icons.wb_sunny_rounded;
        break;
      case "Night":
        icon = Icons.nights_stay_rounded;
        break;
      case "Sunset":
        icon = Icons.wb_twilight_rounded;
        break;
      default:
        icon = Icons.wb_sunny_rounded;
    }

    return InkWell(
      onTap: () => setState(() => selectedTimeOfDay = timeOfDay),
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
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              timeOfDay,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}