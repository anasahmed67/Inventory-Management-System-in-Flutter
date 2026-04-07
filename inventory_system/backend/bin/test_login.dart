import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final dbHost = env['DB_HOST'] ?? 'localhost';
  final dbPort = int.tryParse(env['DB_PORT'] ?? '3306') ?? 3306;
  final dbUser = env['DB_USER'] ?? 'root';
  final dbPass = env['DB_PASSWORD'] ?? '';
  final dbName = env['DB_NAME'] ?? 'inventory_db';

  final dbSettings = ConnectionSettings(
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: dbPass,
    db: dbName,
  );

  print('Database Settings: Host=$dbHost, User=$dbUser, DB=$dbName, PasswordUsed=${dbPass.isNotEmpty}');

  final conn = await MySqlConnection.connect(dbSettings);
  final results = await conn.query('SELECT id, username, email, password, role FROM users WHERE email = ?', ['admin@example.com']);
  
  if (results.isEmpty) {
    print('User not found.');
    await conn.close();
    return;
  }

  final user = results.first;
  final rawPassword = user['password'];
  print('Raw Password Type: ${rawPassword.runtimeType}');
  print('Raw Password: $rawPassword');

  dynamic _convertToSerializable(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    } else if (value is Uint8List) {
      try {
        return utf8.decode(value);
      } catch (_) {
        return value.toString();
      }
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _convertToSerializable(v)));
    } else if (value is List) {
      return value.map((e) => _convertToSerializable(e)).toList();
    } else {
      return value.toString();
    }
  }

  final storedPassword = _convertToSerializable(rawPassword).toString();
  print('Stored Password: $storedPassword');
  
  if ('admin123' != storedPassword) {
    print('Password mismatch! Expected: admin123');
  } else {
    print('Password match!');
  }

  await conn.close();
}
