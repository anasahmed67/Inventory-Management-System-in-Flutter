import 'package:mysql1/mysql1.dart';

void main() async {
  final configs = [
    {'user': 'dart_user', 'pass': 'admin123'},
    {'user': 'root', 'pass': null},
    {'user': 'root', 'pass': 'root'},
    {'user': 'root', 'pass': 'admin123'},
    {'user': 'dart_user', 'pass': null},
    {'user': 'inventory_user', 'pass': 'admin123'},
  ];

  for (var config in configs) {
    try {
      final dbSettings = ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: config['user']!,
        password: config['pass'],
        db: 'inventory_db',
      );
      final conn = await MySqlConnection.connect(dbSettings);
      print('SUCCESS with User: ${config['user']}, Pass: ${config['pass'] ?? "null"}');
      await conn.close();
      return; 
    } catch (e) {
      print('FAILED with User: ${config['user']}, Pass: ${config['pass'] ?? "null"} - Error: ${e.toString().split('\n').first}');
    }
  }
}
