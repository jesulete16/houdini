import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:houdini/home_page.dart';
import 'package:houdini/register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> _signInWithEmail() async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      _showError("Error al iniciar sesión: ${e.toString()}");
    }
  }

  Future<void> _resetPassword() async {
    if (emailController.text.isNotEmpty) {
      try {
        await supabase.auth.resetPasswordForEmail(emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Se ha enviado un correo para restablecer la contraseña"),
            backgroundColor: Colors.cyanAccent,
          ),
        );
      } catch (e) {
        _showError("Error al enviar correo: ${e.toString()}");
      }
    } else {
      _showError("Introduce tu correo para restablecer la contraseña");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900, Colors.cyanAccent.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Houdini",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(blurRadius: 10, color: Colors.cyanAccent, offset: Offset(0, 0)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(emailController, "Correo Electrónico"),
                const SizedBox(height: 12),
                _buildTextField(passwordController, "Contraseña", obscureText: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signInWithEmail,
                  style: _buttonStyle(),
                  child: const Text("Iniciar Sesión"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    "¿Has olvidado tu contraseña?",
                    style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  style: _buttonStyle(),
                  child: const Text("Registrarse"),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                  child: const Text(
                    "Volver a Inicio",
                    style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return SizedBox(
      width: 300,
      height: 50,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.cyanAccent),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.6), width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.cyanAccent, width: 2.5),
            borderRadius: BorderRadius.circular(20),
          ),
          filled: true,
          fillColor: Colors.white10,
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.cyanAccent,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      shadowColor: Colors.cyanAccent.withOpacity(0.5),
      elevation: 10,
    );
  }
}
