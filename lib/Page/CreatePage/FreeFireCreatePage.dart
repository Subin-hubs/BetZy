import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FFCreatePage extends StatefulWidget {
  const FFCreatePage({super.key});

  @override
  State<FFCreatePage> createState() => _FFCreatePageState();
}

class _FFCreatePageState extends State<FFCreatePage> {
  // Dropdown selections
  String? selectedMode;
  String? selectedGunAttributes;
  String? selectedUnlimitedItems;
  String? selectedCharacterSkills;

  // Textfield controller for points
  TextEditingController pointsController = TextEditingController();

  // Dropdown options
  final List<String> modes = [
    "Clash Squad",
    "Lone Wolf",
    "Full Map",
  ];

  final List<String> yesNoOptions = ["Yes", "No"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Free Fire Match"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ----------------- Mode -----------------
            buildTitle("Select Mode"),
            buildDropdown(
              value: selectedMode,
              hint: "Choose Mode",
              items: modes,
              onChanged: (v) => setState(() => selectedMode = v),
            ),

            const SizedBox(height: 20),

            // ----------------- Gun Attributes -----------------
            buildTitle("Gun Attributes"),
            buildDropdown(
              value: selectedGunAttributes,
              hint: "Select Yes or No",
              items: yesNoOptions,
              onChanged: (v) => setState(() => selectedGunAttributes = v),
            ),

            const SizedBox(height: 20),

            // ----------------- Unlimited Items -----------------
            buildTitle("Unlimited Items"),
            buildDropdown(
              value: selectedUnlimitedItems,
              hint: "Select Yes or No",
              items: yesNoOptions,
              onChanged: (v) => setState(() => selectedUnlimitedItems = v),
            ),

            const SizedBox(height: 20),

            // ----------------- Character Skills → New -----------------
            buildTitle("Character Skills"),
            buildDropdown(
              value: selectedCharacterSkills,
              hint: "Select Yes or No",
              items: yesNoOptions,
              onChanged: (v) => setState(() => selectedCharacterSkills = v),
            ),

            const SizedBox(height: 20),

            // ----------------- Points (Now TextField) -----------------
            buildTitle("How Many Points You Want to Play"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter points (e.g. 50)",
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ----------------- Create Button -----------------
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Fluttertoast.showToast(
                    msg: "Match Created Successfully!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.black87,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                },
                child: const Text(
                  "Create Match",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  // ---------- Title ----------
  Widget buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ---------- Dropdown ----------
  Widget buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: Text(hint),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
