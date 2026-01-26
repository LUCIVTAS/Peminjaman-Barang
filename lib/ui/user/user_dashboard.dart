import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
// Import helper pengirim notifikasi
import '../../services/notification_sender.dart'; 

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const UserHome(),
    const UserLoanStatus(),
    const UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade800,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Barang"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

void _showUserNotify(BuildContext context, String message, bool isError) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
    ),
  );
}

String formatTglUser(dynamic data) {
  if (data == null) return "-";
  if (data is Timestamp) {
    DateTime dt = data.toDate();
    String jam = dt.hour.toString().padLeft(2, '0');
    String menit = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month}/${dt.year} ($jam:$menit)";
  }
  return data.toString();
}

// --- HALAMAN 1: KATALOG BARANG ---
class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Katalog Lab")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var item = doc.data() as Map<String, dynamic>;
              int stok = item['stok'] ?? 0;
              return Card(
                child: ListTile(
                  title: Text(item['nama'] ?? "Barang", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Tersedia: $stok unit"),
                  trailing: stok > 0 
                    ? ElevatedButton(onPressed: () => _showLoanDialog(context, doc), child: const Text("Pinjam"))
                    : const Text("Habis", style: TextStyle(color: Colors.red)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLoanDialog(BuildContext context, DocumentSnapshot itemDoc) {
    final qtyController = TextEditingController(text: "1");
    DateTimeRange? range;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Pinjam ${itemDoc['nama']}"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jumlah Unit")),
              const SizedBox(height: 15),
              ListTile(
                title: Text(range == null ? "Pilih Tanggal (Wajib)" : "Tanggal: ${range!.start.day}/${range!.start.month} - ${range!.end.day}/${range!.end.month}"),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                  if (picked != null) setState(() => range = picked);
                },
              ),
              ListTile(
                title: Text(startTime == null ? "Jam Mulai (Opsional)" : "Mulai: ${startTime!.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) setState(() => startTime = picked);
                },
              ),
              ListTile(
                title: Text(endTime == null ? "Jam Selesai (Opsional)" : "Selesai: ${endTime!.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) setState(() => endTime = picked);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(onPressed: () async {
              if (range == null) {
                _showUserNotify(context, "Tanggal wajib diisi!", true);
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                int qty = int.parse(qtyController.text);

                DateTime startFinal = DateTime(range!.start.year, range!.start.month, range!.start.day, startTime?.hour ?? 0, startTime?.minute ?? 0);
                DateTime endFinal = DateTime(range!.end.year, range!.end.month, range!.end.day, endTime?.hour ?? 23, endTime?.minute ?? 59);

                await FirebaseFirestore.instance.collection('loans').add({
                  'itemId': itemDoc.id,
                  'itemName': itemDoc['nama'],
                  'userId': user!.uid,
                  'userEmail': user.email,
                  'quantity': qty,
                  'startDate': Timestamp.fromDate(startFinal),
                  'endDate': Timestamp.fromDate(endFinal),
                  'status': 'Pending',
                  'requestDate': FieldValue.serverTimestamp(),
                });
                await itemDoc.reference.update({'stok': FieldValue.increment(-qty)});
                
                // --- TAMBAHAN: KIRIM NOTIFIKASI KE ADMIN ---
                await NotificationSender.sendNotification(
                  toTopic: 'admin_notif',
                  title: 'Permintaan Pinjam Baru',
                  body: '${user.email} ingin meminjam ${itemDoc['nama']}.',
                );

                Navigator.pop(context);
                _showUserNotify(context, "Permintaan berhasil dikirim!", false);
              } catch (e) {
                _showUserNotify(context, "Gagal: $e", true);
              }
            }, child: const Text("Kirim")),
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN 2: RIWAYAT ---
class UserLoanStatus extends StatelessWidget {
  const UserLoanStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat Peminjaman"),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: EdgeInsets.symmetric(horizontal: 20),
            tabs: [Tab(text: "Pending"), Tab(text: "Dipinjam"), Tab(text: "Kembali"), Tab(text: "Ditolak")],
          ),
        ),
        body: TabBarView(children: [
          _buildList(context, user!.uid, 'Pending'),
          _buildList(context, user.uid, 'Approved'),
          _buildList(context, user.uid, 'Returned'),
          _buildList(context, user.uid, 'Rejected'),
        ]),
      ),
    );
  }

  Widget _buildList(BuildContext context, String uid, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('loans')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("Tidak ada data $status"));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var loan = doc.data() as Map<String, dynamic>;
            int qty = loan['quantity'] ?? 1;
            String itemName = loan['itemName'] ?? "Barang";

            return Card(
              child: ListTile(
                title: Text("$itemName ($qty Unit)", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text("Request: ${formatTglUser(loan['requestDate'])}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    Text("Jadwal: ${formatTglUser(loan['startDate'])} - ${formatTglUser(loan['endDate'])}", style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (status == 'Approved')
                    IconButton(
                      icon: const Icon(Icons.assignment_return, color: Colors.orange), 
                      onPressed: () => _returnItem(context, doc.id, loan['itemId'], qty, itemName)
                    ),
                  if (status == 'Returned' || status == 'Rejected')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red), 
                      onPressed: () => _deleteHistory(context, doc.reference, itemName)
                    ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  void _returnItem(BuildContext context, String loanId, String itemId, int qty, String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('loans').doc(loanId).update({'status': 'Returned'});
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({'stok': FieldValue.increment(qty)});
      
      // --- TAMBAHAN: KIRIM NOTIFIKASI KE ADMIN ---
      await NotificationSender.sendNotification(
        toTopic: 'admin_notif',
        title: 'Barang Dikembalikan',
        body: '${user?.email} telah mengembalikan $name ($qty unit).',
      );

      _showUserNotify(context, "$name berhasil dikembalikan!", false);
    } catch (e) {
      _showUserNotify(context, "Gagal mengembalikan $name", true);
    }
  }

  void _deleteHistory(BuildContext context, DocumentReference docRef, String name) async {
    try {
      await docRef.delete();
      _showUserNotify(context, "Riwayat $name telah dihapus!", false);
    } catch (e) {
      _showUserNotify(context, "Gagal menghapus riwayat", true);
    }
  }
}

// --- HALAMAN 3: PROFIL USER ---
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.person, size: 80, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 20),
              const Text("Profil Mahasiswa", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(
                user?.email ?? "User Email", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _showUserNotify(context, "Berhasil keluar", false);
                    auth.logout();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("LOGOUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}