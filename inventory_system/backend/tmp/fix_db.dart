import 'package:mysql1/mysql1.dart';
import 'dart:io';

void main() async {
  final settings = ConnectionSettings(
    host: '127.0.0.1',
    port: 3306,
    user: 'root',
    password: null,
    db: 'inventory_db',
  );

  try {
    final conn = await MySqlConnection.connect(settings);
    print('Connected to database.');

    // 1. Drop existing FK if it exists (using a safer approach)
    try {
      await conn.query('ALTER TABLE transactions DROP FOREIGN KEY transactions_ibfk_1');
      print('Dropped old foreign key.');
    } catch (e) {
      print('Notice: Could not drop FK (might not exist with that name): $e');
    }

    // 2. Add FK with ON DELETE CASCADE
    await conn.query('''
      ALTER TABLE transactions 
      ADD CONSTRAINT transactions_ibfk_1 
      FOREIGN KEY (product_id) 
      REFERENCES products(id) 
      ON DELETE CASCADE
    ''');
    print('Added foreign key with ON DELETE CASCADE.');

    await conn.close();
    print('Done.');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
