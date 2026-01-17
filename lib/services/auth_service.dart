import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserCredential?> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _db.collection('users').doc(res.user!.uid).set({
      'email': email,
      'role': 'user',
      'name': email.split('@')[0],
      'uid': res.user!.uid,
      'createdAt': DateTime.now(),
    });
  }

  Future<String> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc['role'] : 'user';
  }

  Future<void> logout() => _auth.signOut();
}