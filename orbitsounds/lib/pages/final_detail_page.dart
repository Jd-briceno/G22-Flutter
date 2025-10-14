import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:melodymuse/components/achivement_popup.dart'; // 👈 importa el popup
import 'package:melodymuse/pages/complete_profile_page.dart';
import 'package:melodymuse/pages/home_screen.dart';
import 'package:heroicons/heroicons.dart';
import 'package:country_picker/country_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinalDetailsPage extends StatefulWidget {
  final User user;
  const FinalDetailsPage({super.key, required this.user});

  @override
  State<FinalDetailsPage> createState() => _FinalDetailsPageState();
}

class _FinalDetailsPageState extends State<FinalDetailsPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  File? _profileImage;
  String? _selectedGender;
  Country? _selectedCountry;
  bool saving = false;

  final picker = ImagePicker();

  final List<String> genders = [
    "Male",
    "Female",
    "Non-binary",
    "Other",
    "Prefer not to say"
  ];

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _nicknameFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  /// 🎖️ Mostrar popup de logro inicial
  Future<void> unlockInitialAchievement(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final achievementsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('achievements');

    // ⚡ Evita duplicados
    final snapshot = await achievementsRef
        .where('target', isEqualTo: 'Profile Completed')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await achievementsRef.add({
        'target': 'Profile Completed',
        'title': 'Cadet',
        'icon': 'assets/medals/cadet.png', // 👈 ícono que usarás para este logro
        'unlockedAt': FieldValue.serverTimestamp(),
      });

      // 🎖️ Mostrar popup y esperar que se cierre
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AchievementPopup(
          genre: 'Profile Completed',
          title: 'Welcome Cadet',
          iconPath: 'assets/medals/cadet.png',
        ),
      );
    }
  }

  Future<void> _saveFinalDetails() async {
    if (_fullNameController.text.trim().isEmpty ||
        _nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Full Name and Nickname are required")),
      );
      return;
    }

    setState(() => saving = true);

    String? imageUrl;
    if (_profileImage != null) {
      imageUrl = _profileImage!.path;
    }

    final data = {
      "fullName": _fullNameController.text.trim(),
      "nickname": _nicknameController.text.trim(),
      "description": _descriptionController.text.trim(),
      "nationality": _selectedCountry != null
          ? {
              "code": _selectedCountry!.countryCode,
              "name": _selectedCountry!.name,
              "flag": _selectedCountry!.flagEmoji,
            }
          : null,
      "gender": _selectedGender,
      "profileImageUrl": imageUrl,
      "title": "Cadet",
      "createdAt": DateTime.now(),
      "updatedAt": DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .set(data, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("fullName", (data["fullName"] ?? "").toString());
    await prefs.setString("nickname", (data["nickname"] ?? "").toString());
    await prefs.setString("description", (data["description"] ?? "").toString());
    await prefs.setString("gender", (data["gender"] ?? "").toString());
    await prefs.setString("profileImageUrl", (data["profileImageUrl"] ?? "").toString());
    await prefs.setString("title", (data["title"] ?? "Cadet").toString());
    if (data["nationality"] != null) {
      final nationality = data["nationality"] as Map<String, dynamic>;
      await prefs.setString("nationality_code", (nationality["code"] ?? "").toString());
      await prefs.setString("nationality_name", (nationality["name"] ?? "").toString());
      await prefs.setString("nationality_flag", (nationality["flag"] ?? "").toString());
    }

    // 🎖️ Muestra el popup de logro antes de ir al Home
    await unlockInitialAchievement(context);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  InputDecoration _inputStyle(String label, FocusNode focus, String value) {
    const focusColor = Color(0xFF0095FC);
    final hasFocusOrValue = focus.hasFocus || value.isNotEmpty;

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: "RobotoMono",
        color: Colors.white70,
      ),
      filled: true,
      fillColor: hasFocusOrValue
          ? focusColor.withOpacity(0.3)
          : const Color(0xFFB4B1B8).withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: focusColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF010B19);
    const Color focusColor = Color(0xFF0095FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompleteProfilePage(user: widget.user),
              ),
            );
          },
        ),
        title: const Text(
          "Fill Your Profile",
          style: TextStyle(
            fontFamily: "EncodeSansExpanded",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person,
                          size: 80, color: Colors.white70)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -10,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: focusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HeroIcon(
                        HeroIcons.pencil,
                        color: bgColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _fullNameController,
              focusNode: _fullNameFocus,
              style: const TextStyle(color: Colors.white, fontFamily: "RobotoMono"),
              decoration: _inputStyle(
                "Full Name",
                _fullNameFocus,
                _fullNameController.text,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nicknameController,
              focusNode: _nicknameFocus,
              style: const TextStyle(color: Colors.white, fontFamily: "RobotoMono"),
              decoration: _inputStyle(
                "Nickname",
                _nicknameFocus,
                _nicknameController.text,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              maxLines: 2,
              maxLength: 120,
              style: const TextStyle(color: Colors.white, fontFamily: "RobotoMono"),
              decoration: _inputStyle(
                "Description",
                _descriptionFocus,
                _descriptionController.text,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: false,
                  onSelect: (Country country) {
                    setState(() => _selectedCountry = country);
                  },
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: _selectedCountry != null
                      ? focusColor.withOpacity(0.3)
                      : const Color(0xFFB4B1B8).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: focusColor),
                ),
                child: Row(
                  children: [
                    if (_selectedCountry != null)
                      Text(
                        _selectedCountry!.flagEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    if (_selectedCountry != null) const SizedBox(width: 8),
                    Text(
                      _selectedCountry?.name ?? "Select Nationality",
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "RobotoMono",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: _inputStyle("Gender", FocusNode(), _selectedGender ?? ""),
              dropdownColor: bgColor,
              style: const TextStyle(color: Colors.white, fontFamily: "RobotoMono"),
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _saveFinalDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: focusColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Continue",
                        style: TextStyle(
                          fontFamily: "RobotoMono",
                          fontWeight: FontWeight.bold,
                          color: bgColor,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
