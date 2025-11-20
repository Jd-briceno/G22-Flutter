import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:melodymuse/views/final_detail_page.dart';

class CompleteProfilePage extends StatefulWidget {
  final User user;
  const CompleteProfilePage({super.key, required this.user});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final List<String> selectedInterests = [];

  final List<String> interests = [
    "Travel","DnD session", "Workout", "Study", "Sleep", "Party", "Relax", "Focus", "Drive",
    "Chill", "Work", "Dance", "Cook", "Meditate", "Gaming", "Read", "Clean",
    "Coffee Afternoon", "Rain", "Sunset Vibes", "Friends", "Nature", "Love"
  ];

  bool saving = false;

  Future<void> _saveProfile({bool skip = false}) async {
    setState(() => saving = true);

    final data = {
      "email": widget.user.email,
      "createdAt": DateTime.now(),
      "profileStage": "interests_done", // 👈 Nuevo campo que marca progreso
      if (!skip) "interests": selectedInterests,
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .set(data, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FinalDetailsPage(user: widget.user), // 🔹 cambio aquí
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF010B19);
    const Color focusColor = Color(0xFF0095FC);
    final Color borderColor = const Color(0xFFB4B1B8).withOpacity(0.3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        toolbarHeight: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            "Choose Your Interest",
            style: TextStyle(
              fontFamily: "EncodeSansExpanded",
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose your interests and get the best music recommendations. "
              "Don’t worry, you can always change them later.",
              style: TextStyle(
                fontFamily: "RobotoMono",
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // 🔹 Intereses en Wrap dinámico
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: interests.map((interest) {
                    final bool isSelected = selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedInterests.remove(interest);
                          } else {
                            selectedInterests.add(interest);
                          }
                        });
                      },
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? focusColor : bgColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: focusColor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            interest,
                            style: TextStyle(
                              fontFamily: "RobotoMono",
                              color: isSelected ? bgColor : Colors.white, // 🔹 CAMBIO
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Botones Skip / Continue
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => _saveProfile(skip: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      backgroundColor: borderColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        fontFamily: "RobotoMono",
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving ? null : () => _saveProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: focusColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontFamily: "RobotoMono",
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
