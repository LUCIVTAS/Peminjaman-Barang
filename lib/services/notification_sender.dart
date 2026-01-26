import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart'; 

class NotificationSender {
  static Future<void> sendNotification({
    required String toTopic,
    required String title,
    required String body,
  }) async {
    try {
      final String response = await rootBundle.loadString('lib/assets/service-account.json');
      final data = json.decode(response);

      final accountCredentials = ServiceAccountCredentials.fromJson(data);
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);

      final String projectId = data['project_id'];
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      final msg = {
        'message': {
          'topic': toTopic,
          'notification': {
            'title': title,
            'body': body,
          },
          // TAMBAHKAN BAGIAN DATA DI BAWAH INI
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'priority': 'high',
          },
          'android': {
            'priority': 'high', // Tetap gunakan priority high
            'notification': {
              'sound': 'default',
              'default_sound': true,
              'notification_priority': 'PRIORITY_HIGH',
              'visibility': 'PUBLIC', // Membuat notifikasi muncul meski layar terkunci
            },
          },
        }
      };

      final res = await authClient.post(
        Uri.parse(url),
        body: jsonEncode(msg),
      );

      if (res.statusCode == 200) {
        print("✅ Notifikasi Berhasil Terkirim!");
      } else {
        print("❌ Gagal: ${res.body}");
      }

      authClient.close();
      
    } catch (e) {
      print("⚠️ Error NotificationSender: $e");
    }
  }
}