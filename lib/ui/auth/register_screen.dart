import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // --- TAMBAHAN: Variabel kontrol hide password ---
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // FUNGSI FEEDBACK (SNACKBAR MELAYANG)
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
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Buat Akun Baru",
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

              // INPUT PASSWORD (DENGAN TOGGLE HIDE)
              TextField(
                controller: _passwordController,
                obscureText: _obscurePass, // Menggunakan variabel kontrol
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // INPUT KONFIRMASI PASSWORD (DENGAN TOGGLE HIDE)
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm, // Menggunakan variabel kontrol
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              // TOMBOL DAFTAR
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
                        String confirm = _confirmPasswordController.text.trim();

                        if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
                          _showFeedback("Semua kolom wajib diisi!", true);
                          return;
                        }

                        if (!email.contains('@')) {
                          _showFeedback("Format email tidak valid!", true);
                          return;
                        }

                        if (pass.length < 6) {
                          _showFeedback("Password minimal 6 karakter!", true);
                          return;
                        }

                        if (pass != confirm) {
                          _showFeedback("Konfirmasi password tidak cocok!", true);
                          return;
                        }

                        setState(() => _isLoading = true);

                        try {
                          await auth.register(email, pass);
                          _showFeedback("Akun berhasil dibuat! Silahkan masuk.", false);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) Navigator.pop(context);
                          });
                        } catch (e) {
                          _showFeedback("Gagal mendaftar: Email mungkin sudah digunakan", true);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text(
                        "DAFTAR SEKARANG", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}