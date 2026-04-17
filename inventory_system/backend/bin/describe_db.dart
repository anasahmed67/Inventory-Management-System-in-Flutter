import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

void main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final dbHost = env['DB_HOST'] ?? 'localhost';
  final dbPort = int.tryParse(env['DB_PORT'] ?? '3306') ?? 3306;
  final dbUser = env['DB_USER'] ?? 'root';
  final dbPass = (env['DB_PASSWORD']?.isEmpty ?? true) ? null : env['DB_PASSWORD'];
  final dbName = env['DB_NAME'] ?? 'inventory_db';

  final settings = ConnectionSettings(
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: dbPass,
    db: dbName,
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    print('Successfully connected to $dbName');
    
    final results = await conn.query('DESCRIBE products');
    print('--- Products Table Schema ---');
    for (var row in results) {
      print('Field: ${row[0]}, Type: ${row[1]}, Null: ${row[2]}, Key: ${row[3]}');
    }
    
    await conn.close();
  } catch (e) {
    print('Error: $e');
  }
}
