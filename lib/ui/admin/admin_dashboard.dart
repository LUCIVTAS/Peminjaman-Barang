import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/pdf_service.dart';
// Import helper pengirim notifikasi
import '../../services/notification_sender.dart'; 

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const AdminRequestPage(),
    const AdminStockPage(),
    const AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade900,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: "Permintaan"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Stok"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}

void _showAdminNotify(BuildContext context, String message, bool isError) {
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

// FORMAT TANGGAL + JAM
String formatTgl(dynamic data) {
  if (data == null) return "-";
  if (data is Timestamp) {
    DateTime dt = data.toDate();
    String jam = dt.hour.toString().padLeft(2, '0');
    String menit = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month}/${dt.year} ($jam:$menit)";
  }
  return data.toString();
}

class AdminRequestPage extends StatelessWidget {
  const AdminRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manajemen Pinjaman"),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('loans').snapshots(),
              builder: (context, snapshot) {
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () async {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      bool isDownloaded = await PdfService.generateLoanReport(snapshot.data!.docs);
                      if (isDownloaded) {
                        _showAdminNotify(context, "Laporan berhasil disimpan!", false);
                      } else {
                        _showAdminNotify(context, "Penyimpanan dibatalkan", true);
                      }
                    } else {
                      _showAdminNotify(context, "Tidak ada data peminjaman", true);
                    }
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [Tab(text: "Pending"), Tab(text: "Dipinjam"), Tab(text: "Kembali"), Tab(text: "Ditolak")],
          ),
        ),
        body: TabBarView(children: [
          _buildList(context, 'Pending'),
          _buildList(context, 'Approved'),
          _buildList(context, 'Returned'),
          _buildList(context, 'Rejected'),
        ]),
      ),
    );
  }

  Widget _buildList(BuildContext context, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('loans').where('status', isEqualTo: status).orderBy('requestDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var loan = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text("${loan['itemName']} (${loan['quantity']} Unit)", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text("Peminjam: ${loan['userEmail']}"),
                    Text("Request: ${formatTgl(loan['requestDate'])}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    Text("Durasi: ${formatTgl(loan['startDate'])} - ${formatTgl(loan['endDate'])}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (status == 'Pending') ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green), 
                      onPressed: () => _handleAction(context, doc.id, 'Approved', loan['itemName'], loan['itemId'], 0)
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red), 
                      onPressed: () => _handleAction(context, doc.id, 'Rejected', loan['itemName'], loan['itemId'], loan['quantity'])
                    ),
                  ],
                  IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => _delete(context, doc.id)),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  void _handleAction(BuildContext context, String docId, String status, String itemName, String? itemId, int qty) async {
    try {
      await FirebaseFirestore.instance.collection('loans').doc(docId).update({'status': status});
      
      if (status == 'Rejected' && itemId != null) {
        await FirebaseFirestore.instance.collection('items').doc(itemId).update({'stok': FieldValue.increment(qty)});
      }

      // --- TAMBAHAN: KIRIM NOTIFIKASI KE USER ---
      String statusText = status == 'Approved' ? 'DISETUJUI' : 'DITOLAK';
      await NotificationSender.sendNotification(
        toTopic: 'user_notif',
        title: 'Update Peminjaman',
        body: 'Permintaan pinjam $itemName Anda telah $statusText oleh Admin.',
      );

      _showAdminNotify(context, "Status diperbarui & Notifikasi dikirim", false);
    } catch (e) {
      _showAdminNotify(context, "Gagal memperbarui status: $e", true);
    }
  }

  void _delete(BuildContext context, String id) async {
    await FirebaseFirestore.instance.collection('loans').doc(id).delete();
    _showAdminNotify(context, "Data dihapus", false);
  }
}

class AdminStockPage extends StatelessWidget {
  const AdminStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gudang Barang")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () => _showItemDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
              return Card(
                child: ListTile(
                  title: Text(item['nama'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Stok: ${item['stok']} Unit"),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showItemDialog(context, doc)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                      doc.reference.delete();
                      _showAdminNotify(context, "Barang dihapus", false);
                    }),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showItemDialog(BuildContext context, [DocumentSnapshot? doc]) {
    final nameCtrl = TextEditingController(text: doc != null ? doc['nama'] : "");
    final stockCtrl = TextEditingController(text: doc != null ? doc['stok'].toString() : "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "Tambah Barang" : "Edit Barang"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Barang")),
          TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Jumlah Stok"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(onPressed: () async {
            if (doc == null) {
              await FirebaseFirestore.instance.collection('items').add({'nama': nameCtrl.text, 'stok': int.parse(stockCtrl.text)});
            } else {
              await doc.reference.update({'nama': nameCtrl.text, 'stok': int.parse(stockCtrl.text)});
            }
            Navigator.pop(context);
            _showAdminNotify(context, "Berhasil disimpan", false);
          }, child: const Text("Simpan"))
        ],
      ),
    );
  }
}

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

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
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 25),
              const Text("Administrator Mode", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(user?.email ?? "Admin Email", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    _showAdminNotify(context, "Admin Logout", false);
                    auth.logout();
                  },
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text("KELUAR DARI SISTEM", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}