import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Import menggunakan Full Package Name sesuai pubspec.yaml
import 'package:peminjamanbarang/firebase_options.dart';
import 'package:peminjamanbarang/services/auth_service.dart';
import 'package:peminjamanbarang/ui/auth/login_screen.dart';
import 'package:peminjamanbarang/ui/user/user_dashboard.dart';
import 'package:peminjamanbarang/ui/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Mendaftarkan class AuthService agar bisa diakses di seluruh aplikasi
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Sistem Peminjaman Lab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: auth.userStream,
      builder: (context, snapshot) {
        // Cek status koneksi stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Jika user sudah terautentikasi (login)
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String>(
            future: auth.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              // Logika Role-Based Access Control (Admin vs User)
              if (roleSnap.data == 'admin') {
                return AdminDashboard();
              } else {
                return UserDashboard();
              }
            },
          );
        }

        // Jika tidak ada user yang login, tampilkan layar login
        return LoginScreen();
      },
    );
  }
}