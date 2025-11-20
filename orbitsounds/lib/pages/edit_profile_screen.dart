import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // <-- comentado por ahora

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nicknameController;
  late TextEditingController descriptionController;
  String? selectedTitle;
  File? newProfileImage; // imagen seleccionada localmente
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nicknameController =
        TextEditingController(text: widget.userData['nickname'] ?? '');
    descriptionController =
        TextEditingController(text: widget.userData['description'] ?? '');
    selectedTitle = widget.userData['title'] ?? 'Cadet';
  }

  @override
  void dispose() {
    nicknameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // 📸 Elegir imagen (galería)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        newProfileImage = File(pickedFile.path);
      });
    }
  }

  // 🔎 Cargar títulos desbloqueados desde /users/{uid}/achievements
  Future<List<String>> _fetchUnlockedTitles() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .get();

    final titles = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final t = data['title'];
          return t is String ? t : null;
        })
        .whereType<String>()
        .toList();

    // quitar duplicados (por si acaso)
    return titles.toSet().toList();
  }

  // 💾 Guardar cambios en Firestore (sin subir a Storage por ahora)
  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => saving = true);

    String? imagePath = widget.userData['profileImageUrl'];

    // Si seleccionaste una nueva imagen, guardamos la ruta local (no subimos a Storage)
    if (newProfileImage != null) {
      imagePath = newProfileImage!.path;
    }

    // ----- Código para activar Firebase Storage (comentado) -----
    /*
    if (newProfileImage != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(newProfileImage!);
      imagePath = await ref.getDownloadURL();
    }
    */
    // ---------------------------------------------------------------------------

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'nickname': nicknameController.text.trim(),
      'description': descriptionController.text.trim(),
      'title': selectedTitle,
      'profileImageUrl': imagePath,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    setState(() => saving = false);
    Navigator.pop(context); // vuelve al profile
  }

  ImageProvider _imageProviderFromPath(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    if (path.startsWith('/data/')) return FileImage(File(path));
    if (path.startsWith('http')) return NetworkImage(path);
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = newProfileImage != null
        ? FileImage(newProfileImage!)
        : _imageProviderFromPath(widget.userData['profileImageUrl'] as String?);

    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Editar Perfil", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: saving ? const CircularProgressIndicator() : const Icon(Icons.check, color: Colors.white),
            onPressed: saving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar y picker
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(radius: 60, backgroundImage: currentImage, backgroundColor: Colors.grey.shade800),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _pickImage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nickname
            TextField(
              controller: nicknameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nickname",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 18),

            // Descripción con límite de caracteres
            TextField(
              controller: descriptionController,
              maxLines: 2,
              maxLength: 120, // 🧩 Límite de caracteres
              style: const TextStyle(color: Colors.white, fontFamily: "RobotoMono"),
              decoration: const InputDecoration(
                counterStyle: TextStyle(color: Colors.white54), // contador visible
                labelText: "Descripción",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              onChanged: (_) => setState(() {}), // refresca contador si quieres dinámico
            ),

            const SizedBox(height: 18),

            // Dropdown de títulos (aseguramos que "Cadet" esté presente)
            FutureBuilder<List<String>>(
              future: _fetchUnlockedTitles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return const Text("Error cargando títulos", style: TextStyle(color: Colors.redAccent));
                }

                // lista de títulos desde achievements
                final fetched = snapshot.data ?? <String>[];
                final titles = List<String>.from(fetched); // copia mutable

                const defaultTitle = 'Cadet';
                // Asegurarnos de que "Cadet" esté en la lista
                if (!titles.contains(defaultTitle)) titles.insert(0, defaultTitle);

                // Evitar duplicados si selectedTitle es nulo o no está en la lista
                if (selectedTitle == null || !titles.contains(selectedTitle)) {
                  selectedTitle = widget.userData['title'] ?? defaultTitle;
                  if (!titles.contains(selectedTitle)) {
                    selectedTitle = defaultTitle;
                  }
                }

                return DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF010B19),
                  value: selectedTitle,
                  items: titles.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setState(() => selectedTitle = v),
                  decoration: const InputDecoration(
                    labelText: "Selecciona tu título",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
