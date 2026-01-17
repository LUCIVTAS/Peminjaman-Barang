import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // --- TAMBAHAN: Variabel kontrol hide password ---

  // FUNGSI SNACKBAR MENGAMBANG YANG BERSIH
  void _showFeedback(String message, bool isError) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vpn_key_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Login Lab-Track",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // INPUT EMAIL
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // INPUT PASSWORD (DENGAN FITUR HIDE/SHOW)
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword, // --- UBAHAN: Menggunakan variabel ---
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  // --- TAMBAHAN: Ikon Mata ---
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              // TOMBOL LOGIN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading 
                    ? null 
                    : () async {
                        String email = _emailController.text.trim();
                        String pass = _passwordController.text.trim();

                        if (email.isEmpty || pass.isEmpty) {
                          _showFeedback("Email dan Password wajib diisi!", true);
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          await auth.login(email, pass);
                          _showFeedback("Berhasil Masuk!", false);
                        } catch (e) {
                          _showFeedback("Gagal: Email atau Password salah", true);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text(
                        "LOGIN", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text("Belum punya akun? Daftar Sekarang"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}