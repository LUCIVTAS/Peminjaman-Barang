import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Realtime Items (Level A)
  Stream<List<ItemModel>> streamItems() {
    return _db.collection('items').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ItemModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Pengajuan Pinjam (Level B)
  Future<void> requestLoan(String userId, String userName, ItemModel item) async {
    await _db.collection('loans').add({
      'userId': userId,
      'userName': userName,
      'itemId': item.id,
      'itemName': item.name,
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Realtime Loans untuk Admin (Semua) atau User (Milik sendiri)
  Stream<QuerySnapshot> streamLoans({String? userId}) {
    Query query = _db.collection('loans').orderBy('timestamp', descending: true);
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots();
  }

  // Update Status oleh Admin
  Future<void> updateLoanStatus(String loanId, String newStatus) async {
    await _db.collection('loans').doc(loanId).update({'status': newStatus});
  }
}