import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<bool> generateLoanReport(List<QueryDocumentSnapshot> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0, 
            child: pw.Text("LAPORAN PEMINJAMAN LAB-TRACK", 
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Barang', 'Peminjam', 'Jumlah', 'Status', 'Waktu Request'],
            data: data.map((doc) {
              final item = doc.data() as Map<String, dynamic>;
              return [
                item['itemName'] ?? '-',
                item['userEmail'] ?? '-',
                item['quantity'].toString(),
                item['status'] ?? '-',
                _formatTimestamp(item['requestDate']), // Jam ikut tercetak di PDF
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    final bool result = await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Laporan_Peminjaman_Lab.pdf',
    );
    
    return result;
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "-";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      // Format Jam dan Menit untuk PDF
      String jam = date.hour.toString().padLeft(2, '0');
      String menit = date.minute.toString().padLeft(2, '0');
      return "${date.day}/${date.month}/${date.year} $jam:$menit";
    }
    return "-";
  }
}