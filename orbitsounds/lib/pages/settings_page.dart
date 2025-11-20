import 'package:flutter/material.dart';
import 'package:melodymuse/services/auth_service.dart';
import 'package:melodymuse/pages/login-screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("❌ Error al cerrar sesión: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al cerrar sesión"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF010B19),
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Color(0xFFE9E8EE),
            fontFamily: "Orbitron",
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9E8EE)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text(
              "General",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // ⚙️ Cambiar idioma (placeholder)
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white),
            title: const Text(
              "Idioma",
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Función de idioma próximamente")),
              );
            },
          ),

          const Divider(color: Colors.white24, thickness: 1, height: 32),

          const ListTile(
            title: Text(
              "Cuenta",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // 🚪 Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF0E1524),
                  title: const Text("Cerrar sesión", style: TextStyle(color: Colors.white)),
                  content: const Text(
                    "¿Estás seguro de que deseas cerrar sesión?",
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text("Cerrar sesión", style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _signOut(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
