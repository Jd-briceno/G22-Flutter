import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:heroicons/heroicons.dart';

class AllAchievementsPage extends StatelessWidget {
  final String userId;
  const AllAchievementsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'en_US';

    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF010B19),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const HeroIcon(
            HeroIcons.arrowLeftCircle,
            style: HeroIconStyle.outline,
            color: Colors.white,
            size: 40,
          ),
        ),
        title: const Text(
          'All Achievements',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'EncodeSansExpanded',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .orderBy('unlockedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading achievements.",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "You don’t have any achievements yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.8,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final icon = data['icon'] ?? "assets/images/X.jpg";
                final title = data['title'] ?? "Untitled";
                final timestamp = data['unlockedAt'] as Timestamp?;
                final date = timestamp != null
                    ? DateFormat("MMMM d, yyyy").format(timestamp.toDate())
                    : "Unknown";

                return GestureDetector(
                  onTap: () {
                    _showAchievementPopup(context, icon, title, date);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF010B19),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image(
                            image: icon.toString().startsWith('assets/')
                                ? AssetImage(icon)
                                : NetworkImage(icon) as ImageProvider,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'RobotoMono',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Color(0xFF0095FC),
                            fontFamily: 'RobotoMono',
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 🎇 Popup with blur + scrollable content
  void _showAchievementPopup(
    BuildContext context,
    String icon,
    String title,
    String date,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scale = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scale,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF010B19).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0XFF0095FC)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image(
                              image: icon.toString().startsWith('assets/')
                                  ? AssetImage(icon)
                                  : NetworkImage(icon) as ImageProvider,
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.width * 0.7,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Unlocked on $date",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0095FC),
                              fontFamily: 'RobotoMono',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
