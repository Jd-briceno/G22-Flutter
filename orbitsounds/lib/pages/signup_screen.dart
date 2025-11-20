import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodymuse/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool obscurePass = true;
  bool emailFocused = false;
  bool passFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = const Color(0xFFB4B1B8).withOpacity(0.3);
    final Color focusColor = const Color(0xFF0095FC);

    return Scaffold(
      backgroundColor: const Color(0XFF010B19),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // 🔹 Logo
              Image.asset(
                "assets/images/LogoTentative.png",
                width: 200,
                height: 200,
              ),

              const SizedBox(height: 24),

              // 🔹 Título
              const Text(
                "Create Your Account",
                style: TextStyle(
                  fontFamily: "EncodeSansExpanded",
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // 🔹 Email
              Focus(
                onFocusChange: (focused) {
                  setState(() => emailFocused = focused);
                },
                child: TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: Colors.white70),
                    labelText: "Your Email",
                    labelStyle: const TextStyle(
                      fontFamily: "RobotoMono",
                      color: Colors.white70,
                    ),
                    filled: true,
                    fillColor:
                        emailFocused ? focusColor.withOpacity(0.3) : baseColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: baseColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: focusColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: "RobotoMono",
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Password
              Focus(
                onFocusChange: (focused) {
                  setState(() => passFocused = focused);
                },
                child: TextField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => obscurePass = !obscurePass);
                      },
                    ),
                    labelText: "Password",
                    labelStyle: const TextStyle(
                      fontFamily: "RobotoMono",
                      color: Colors.white70,
                    ),
                    filled: true,
                    fillColor:
                        passFocused ? focusColor.withOpacity(0.3) : baseColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: baseColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: focusColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: "RobotoMono",
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔹 Sign Up button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    String email = emailCtrl.text.trim();
                    String pass = passCtrl.text.trim();

                    if (email.isEmpty || pass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Por favor completa todos los campos")),
                      );
                      return;
                    }

                    User? user =
                        await _authService.registerWithEmail(email, pass);

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("❌ Error al crear la cuenta")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("✅ Cuenta creada con éxito")),
                      );

                      // 🔹 Vuelve al login después de crear la cuenta
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: focusColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Link a Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      fontFamily: "RobotoMono",
                      color: Colors.white70,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // 👈 vuelve al login
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontFamily: "RobotoMono",
                        color: Color(0xFF0095FC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
