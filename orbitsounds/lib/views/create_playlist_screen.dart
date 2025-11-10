import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/spotify_service.dart';
import '../models/track_model.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final SpotifyService _spotifyService = SpotifyService();
  List<Track> _songs = [];
  List<Track> _selectedSongs = [];
  bool _loading = false;

  File? _coverImage;

  // 🔎 debounce para búsqueda en tiempo real
  Timer? _debounce;

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchSongs(query);
    });
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    setState(() => _loading = true);

    final results = await _spotifyService.searchTracks(query);

    setState(() {
      _songs = results;
      _loading = false;
    });
  }

  Future<void> _savePlaylist() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Agrega nombre y al menos una canción")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión")),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("playlists")
        .doc();

    await docRef.set({
      "title": title,
      "description": _descController.text.trim(),
      "coverUrl": _coverImage?.path ?? "", // TODO: subir a Firebase Storage
      "tracks": _selectedSongs.map((t) => {
            "title": t.title,
            "artist": t.artist,
            "duration": t.duration,
            "durationMs": t.durationMs,
            "albumArt": t.albumArt,
            "previewUrl": t.previewUrl,
          }).toList(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      appBar: AppBar(
        title: const Text("Crear Playlist"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _savePlaylist,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Cover picker
            GestureDetector(
              onTap: _pickCover,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _coverImage != null ? FileImage(_coverImage!) : null,
                child: _coverImage == null
                    ? const Icon(Icons.add_a_photo, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nombre de la playlist",
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E1E2C),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Descripción (opcional)",
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF1E1E2C),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Search songs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Buscar canciones en Spotify...",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Color(0xFF1E1E2C),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                onChanged: _onSearchChanged, // 👈 búsqueda en tiempo real
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Results
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final isSelected = _selectedSongs.contains(song);

                return ListTile(
                  leading: Image.network(song.albumArt,
                      width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(song.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(song.artist,
                      style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.add_circle,
                      color: isSelected ? Colors.greenAccent : Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSongs.remove(song);
                        } else {
                          _selectedSongs.add(song);
                        }
                      });
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
