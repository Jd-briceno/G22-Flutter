import 'package:flutter/material.dart';
import 'package:melodymuse/main.dart';
import 'package:melodymuse/pages/signup_screen.dart';
import 'package:melodymuse/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool rememberMe = false;
  bool obscurePass = true;
  bool emailFocused = false;
  bool passFocused = false;
  bool isLoading = false;

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

              const Text(
                "Login to Your Account",
                style: TextStyle(
                  fontFamily: "EncodeSansExpanded",
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // 🔹 Email Field
              Focus(
                onFocusChange: (focused) => setState(() => emailFocused = focused),
                child: TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                    labelText: "Your Email",
                    labelStyle: const TextStyle(fontFamily: "RobotoMono", color: Colors.white70),
                    filled: true,
                    fillColor: emailFocused ? focusColor.withOpacity(0.3) : baseColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: baseColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: focusColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontFamily: "RobotoMono", color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Password Field
              Focus(
                onFocusChange: (focused) => setState(() => passFocused = focused),
                child: TextField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => obscurePass = !obscurePass),
                    ),
                    labelText: "Password",
                    labelStyle: const TextStyle(fontFamily: "RobotoMono", color: Colors.white70),
                    filled: true,
                    fillColor: passFocused ? focusColor.withOpacity(0.3) : baseColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: baseColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: focusColor, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontFamily: "RobotoMono", color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Remember me
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: rememberMe,
                    activeColor: focusColor,
                    onChanged: (val) => setState(() => rememberMe = val ?? false),
                  ),
                  const Text(
                    "Remember me",
                    style: TextStyle(fontFamily: "RobotoMono", color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔹 Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          final user = await _authService.signInWithEmail(
                            emailCtrl.text.trim(),
                            passCtrl.text.trim(),
                          );
                          setState(() => isLoading = false);

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error al iniciar sesión")),
                            );
                          }
                          // ✅ No navegamos manualmente, StreamBuilder lo hará
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: focusColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Sign In",
                          style: TextStyle(
                            fontFamily: "RobotoMono",
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Forgot Password
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(fontFamily: "RobotoMono", color: Colors.white70),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "or continue with",
                      style: TextStyle(fontFamily: "RobotoMono", color: Colors.white70),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                ],
              ),

              const SizedBox(height: 24),

              // 🔹 Social Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialButton(
                    asset: "assets/images/google.png",
                    onTap: () async {
                      setState(() => isLoading = true);
                      final user = await _authService.signInWithGoogle();
                      setState(() => isLoading = false);

                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error al iniciar sesión con Google")),
                        );
                        return;
                      }

                      debugPrint("✅ Login con Google completado: ${user.email}");

                      // 👇 Espera que FirebaseAuth propague el cambio
                      await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);

                      // 👇 Ahora fuerza rebuild global (MyApp volverá a ejecutarse)
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MyApp()),
                        );
                      }
                    },
                  ),



                  _socialButton(
                    asset: "assets/images/apple.png",
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Apple Sign-In próximamente")),
                      );
                    },
                  ),
                  _socialButton(
                    asset: "assets/images/spotify-logo.png",
                    onTap: () async {
                      setState(() => isLoading = true);
                      final user = await _authService.signInWithSpotifySimulated();
                      setState(() => isLoading = false);

                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error al iniciar sesión con Spotify")),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 🔹 Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don’t have an account? ",
                    style: TextStyle(fontFamily: "RobotoMono", color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
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

  /// 🔹 Helper para botones sociales
  Widget _socialButton({required String asset, required VoidCallback onTap}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 88,
        height: 61,
        decoration: BoxDecoration(
          color: const Color(0xFFB4B1B8).withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Image.asset(asset, width: 32, height: 32),
        ),
      ),
    );
  }
}
