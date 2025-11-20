import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Views (updated paths under views/)
import 'package:melodymuse/views/home_screen.dart';
import 'package:melodymuse/views/mood_playlist_screen.dart';
import 'package:melodymuse/views/captain-longbook.dart';
import 'package:melodymuse/views/library_screen.dart';
import 'package:melodymuse/views/profile.dart';
import 'package:melodymuse/views/social_vinyl.dart';
import 'package:melodymuse/views/soul_sync_terminal.dart';
import 'package:melodymuse/views/music_detail_screen.dart';

/// Final screen shown after completing profile/setup.
/// Previously referenced as `FinalDetailsPage(user: ...)` from `complete_profile_page.dart`.
class FinalDetailsPage extends StatefulWidget {
  final User user;

  const FinalDetailsPage({super.key, required this.user});

  @override
  State<FinalDetailsPage> createState() => _FinalDetailsPageState();
}

class _FinalDetailsPageState extends State<FinalDetailsPage> {
  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName ?? 'Explorer';
    final email = widget.user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('All set!'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Welcome, $displayName',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Your profile is ready. You can start exploring OrbitSounds now.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),

            // Primary action → go to Home
            ElevatedButton(
              onPressed: _goHome,
              child: const Text('Go to Home'),
            ),
            const SizedBox(height: 12),

            // Optional quick links to other areas (keep for parity with prior navigation)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoodPlaylistScreen())),
                  child: const Text('Mood Playlists'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoulSyncTerminal())),
                  child: const Text('Soul Sync'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  child: const Text('Library'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Longbook())),
                  child: const Text('Captain’s Logbook'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocialVinylDemo())),
                  child: const Text('Social Vinyl'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileBackstagePage())),
                  child: const Text('Profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
