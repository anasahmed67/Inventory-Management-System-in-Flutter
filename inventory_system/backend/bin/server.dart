import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:mysql1/mysql1.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  // Load environment variables
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final dbHost = env['DB_HOST'] ?? 'localhost';
  final dbPort = int.tryParse(env['DB_PORT'] ?? '3306') ?? 3306;
  final dbUser = env['DB_USER'] ?? 'root';
  final dbPass = env['DB_PASSWORD'] ?? '';
  final dbName = env['DB_NAME'] ?? 'inventory_system';

  // Database Connection Pool
  final dbSettings = ConnectionSettings(
    host: dbHost,
    port: dbPort,
    user: dbUser,
    password: dbPass,
    db: dbName,
  );

  print('Database Settings: Host=$dbHost, User=$dbUser, DB=$dbName, PasswordUsed=${dbPass.isNotEmpty}');

  // Connection manager helper
  Future<MySqlConnection> getConnection() async {
    return await MySqlConnection.connect(dbSettings);
  }

  final router = Router();

  // Helper to convert DB objects (like Blobs) to JSON-serializable types
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
      // Fallback for Blob and other driver-specific types
      return value.toString();
    }
  }

  // Helper for JSON responses
  Response jsonResponse(dynamic data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(_convertToSerializable(data)),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*', // Added for Flutter Web
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-User-Role',
      },
    );
  }

  // --- Auth Endpoints ---

  router.post('/api/login', (Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final email = data['email'];
      final password = data['password'];
      
      print('--- Login Attempt ---');
      print('Email: $email');
      print('Password: $password');

      final conn = await getConnection();
      final results = await conn.query(
        'SELECT id, username, email, password, role FROM users WHERE email = ?',
        [email],
      );
      await conn.close();

      if (results.isEmpty) {
        print('User not found in database.');
        return jsonResponse({'error': 'User not found'}, statusCode: 404);
      }

      final user = results.first;
      final storedPassword = user['password'];
      
      print('User found in DB. Stored Password: $storedPassword');

      // Comparing passwords directly as plain text (Removing BCrypt)
      if (password != storedPassword) {
        print('Password mismatch.');
        return jsonResponse({'error': 'Invalid credentials'}, statusCode: 401);
      }

      print('Login successful!');

      return jsonResponse({
        'user': {
          'id': user['id'],
          'username': user['username'],
          'email': user['email'],
          'role': user['role'],
        },
        'token': 'fake-jwt-token-${user['id']}', // TODO: Replace with real JWT
      });
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  // --- Product Endpoints ---

  router.get('/api/products', (Request request) async {
    try {
      final conn = await getConnection();
      final results = await conn.query('SELECT * FROM products ORDER BY name ASC');
      await conn.close();

      final products = results.map((row) => row.fields).toList();
      return jsonResponse(products);
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.post('/api/products', (Request request) async {
    final role = request.headers['X-User-Role'];
    if (role != 'admin') {
      return jsonResponse({'error': 'Unauthorized: Admin only'}, statusCode: 403);
    }

    try {
      final data = jsonDecode(await request.readAsString());
      final sku = data['sku'];
      final name = data['name'];
      final quantity = data['quantity'] ?? 0;
      final price = data['price'];
      final barcode = data['barcode'];
      final lowStockThreshold = data['low_stock_threshold'] ?? 5;

      final conn = await getConnection();
      // Check for duplicate SKU
      final existingSkuResult = await conn.query('SELECT id FROM products WHERE sku = ?', [sku]);
      if (existingSkuResult.isNotEmpty) {
        await conn.close();
        return jsonResponse({'error': 'Duplicate SKU: A product with this SKU already exists.'}, statusCode: 400);
      }

      // Check for duplicate barcode
      if (barcode != null && barcode.toString().isNotEmpty) {
        final existingBarcodeResult = await conn.query('SELECT id FROM products WHERE barcode = ?', [barcode]);
        if (existingBarcodeResult.isNotEmpty) {
          await conn.close();
          return jsonResponse({'error': 'Duplicate Barcode: A product with this barcode already exists.'}, statusCode: 400);
        }
      }

      final result = await conn.query(
        'INSERT INTO products (sku, name, quantity, price, barcode, low_stock_threshold) VALUES (?, ?, ?, ?, ?, ?)',
        [sku, name, quantity, price, barcode, lowStockThreshold],
      );
      await conn.close();

      return jsonResponse({'id': result.insertId, 'status': 'Product created'}, statusCode: 201);
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.put('/api/products/<id>', (Request request, String id) async {
    final role = request.headers['X-User-Role'];
    if (role != 'admin') {
      return jsonResponse({'error': 'Unauthorized: Admin only'}, statusCode: 403);
    }

    try {
      final data = jsonDecode(await request.readAsString());
      final sku = data['sku'];
      final name = data['name'];
      final quantity = data['quantity'];
      final price = data['price'];
      final barcode = data['barcode'];
      final lowStockThreshold = data['low_stock_threshold'];

      final conn = await getConnection();
      // Check for duplicate SKU (excluding current)
      final existingSkuResult = await conn.query('SELECT id FROM products WHERE sku = ? AND id != ?', [sku, id]);
      if (existingSkuResult.isNotEmpty) {
        await conn.close();
        return jsonResponse({'error': 'Duplicate SKU: This SKU is used by another product.'}, statusCode: 400);
      }

      // Check for duplicate barcode (excluding current)
      if (barcode != null && barcode.toString().isNotEmpty) {
        final existingBarcodeResult = await conn.query('SELECT id FROM products WHERE barcode = ? AND id != ?', [barcode, id]);
        if (existingBarcodeResult.isNotEmpty) {
          await conn.close();
          return jsonResponse({'error': 'Duplicate Barcode: This barcode is used by another product.'}, statusCode: 400);
        }
      }

      await conn.query(
        'UPDATE products SET sku = ?, name = ?, quantity = ?, price = ?, barcode = ?, low_stock_threshold = ? WHERE id = ?',
        [sku, name, quantity, price, barcode, lowStockThreshold, id],
      );
      await conn.close();

      return jsonResponse({'status': 'Product updated'});
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.delete('/api/products/<id>', (Request request, String id) async {
    final role = request.headers['X-User-Role'];
    if (role != 'admin') {
      return jsonResponse({'error': 'Unauthorized: Admin only'}, statusCode: 403);
    }

    try {
      final conn = await getConnection();
      await conn.query('DELETE FROM products WHERE id = ?', [id]);
      await conn.close();

      return jsonResponse({'status': 'Product deleted'});
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.get('/api/products/low-stock', (Request request) async {
    try {
      final conn = await getConnection();
      final results = await conn.query('SELECT * FROM products WHERE quantity <= low_stock_threshold');
      await conn.close();

      final products = results.map((row) => row.fields).toList();
      return jsonResponse(products);
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.get('/api/products/barcode/<code>', (Request request, String code) async {
    try {
      final conn = await getConnection();
      final results = await conn.query('SELECT * FROM products WHERE barcode = ?', [code]);
      await conn.close();

      if (results.isEmpty) {
        return jsonResponse({'error': 'Product not found'}, statusCode: 404);
      }

      return jsonResponse(results.first.fields);
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  // --- Stock Adjustment Endpoints ---

  router.post('/api/stock/adjust', (Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final productId = data['product_id'];
      final quantityChange = data['quantity_change'];
      final userId = data['user_id'];
      final reason = data['reason'];
      final type = (quantityChange >= 0) ? 'IN' : 'OUT';

      final conn = await getConnection();
      bool success = false;
      String errorMsg = '';

      try {
        await conn.transaction((ctx) async {
          // Update product quantity atomically checking stock level
          final res = await ctx.query(
            'UPDATE products SET quantity = quantity + ? WHERE id = ? AND quantity + ? >= 0',
            [quantityChange, productId, quantityChange],
          );
          
          if (res.affectedRows == 0) {
            final exists = await ctx.query('SELECT id FROM products WHERE id = ?', [productId]);
            if (exists.isEmpty) {
              errorMsg = 'Product not found';
            } else {
              errorMsg = 'Stock cannot fall below zero';
            }
            throw Exception('Rollback'); 
          }

          // Log transaction
          await ctx.query(
            'INSERT INTO transactions (product_id, user_id, type, quantity, reason) VALUES (?, ?, ?, ?, ?)',
            [productId, userId, type, quantityChange.abs(), reason],
          );
          success = true;
        });
      } catch (e) {
        // Fallthrough, 'success' remains false
      }
      
      await conn.close();

      if (!success) {
         return jsonResponse({'error': errorMsg.isNotEmpty ? errorMsg : 'Stock adjustment failed'}, statusCode: 400);
      }

      return jsonResponse({'status': 'Stock adjusted and transaction logged'});
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  // --- Reports & Transactions ---

  router.get('/api/transactions', (Request request) async {
    try {
      final conn = await getConnection();
      final results = await conn.query('''
        SELECT t.*, p.name AS product_name, u.username AS user_name 
        FROM transactions t
        JOIN products p ON t.product_id = p.id
        JOIN users u ON t.user_id = u.id
        ORDER BY t.transaction_date DESC
      ''');
      await conn.close();

      final transactions = results.map((row) => row.fields).toList();
      return jsonResponse(transactions);
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.get('/api/reports/stock-value', (Request request) async {
    try {
      final conn = await getConnection();
      final results = await conn.query('SELECT SUM(quantity * price) AS total_value FROM products');
      await conn.close();

      final totalValue = results.first['total_value'] ?? 0;
      return jsonResponse({'total_stock_value': totalValue});
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  // --- Analytics Endpoints ---

  router.get('/api/analytics/stock-summary', (Request request) async {
    try {
      final conn = await getConnection();
      
      // Get counts for different stock levels
      final results = await conn.query('''
        SELECT 
          SUM(CASE WHEN quantity > low_stock_threshold THEN 1 ELSE 0 END) as healthy,
          SUM(CASE WHEN quantity <= low_stock_threshold AND quantity > 0 THEN 1 ELSE 0 END) as low_stock,
          SUM(CASE WHEN quantity = 0 THEN 1 ELSE 0 END) as out_of_stock
        FROM products
      ''');
      await conn.close();

      final summary = results.first;
      return jsonResponse({
        'healthy': summary['healthy'] ?? 0,
        'low_stock': summary['low_stock'] ?? 0,
        'out_of_stock': summary['out_of_stock'] ?? 0,
      });
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  router.get('/api/analytics/top-products', (Request request) async {
    try {
      final conn = await getConnection();
      final results = await conn.query('''
        SELECT name, quantity 
        FROM products 
        ORDER BY quantity DESC 
        LIMIT 5
      ''');
      await conn.close();

      final products = results.map((row) => {
        'name': row['name'],
        'quantity': row['quantity'],
      }).toList();
      
      return jsonResponse(products);
    } catch (e) {
      return jsonResponse({'error': e.toString()}, statusCode: 500);
    }
  });

  // Middleware and server setup
  final overrideHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, X-User-Role',
    'Access-Control-Max-Age': '3600',
  };

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}

// TODO: Helper for password hashing if needed in code (already used BCrypt in login)
String hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}
