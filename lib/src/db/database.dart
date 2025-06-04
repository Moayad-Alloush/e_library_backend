// lib/src/db/database.dart
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart'; // This will now be postgres 3.x.x

class AppDatabase {

  AppDatabase({
    required DotEnv env,
  }) : _env = env;
  final DotEnv _env;

  PostgreSQLConnection? _connection;

  Future<void> open() async {
    // Check if connection is null or not ready using the 3.x.x API
    if (_connection == null || !_connection!.isReady) { // Using isReady
      final host = _env['DB_HOST'] ?? 'localhost';
      final port = int.tryParse(_env['DB_PORT'] ?? '') ?? 5432;
      final databaseName = _env['DB_NAME'] ?? 'your_database_name';
      final username = _env['DB_USER'] ?? 'postgres';
      final password = _env['DB_PASSWORD'] ?? 'password';

      _connection = PostgreSQLConnection(
        host,
        port,
        databaseName,
        username: username,
        password: password,
        // You might want to add other options here, like timeout, sslMode, etc.
        // sslMode: SslMode.prefer, // Example
      );
      try {
        await _connection!.open();
        print('Database connection opened.');
      } catch (e) {
        print('Error opening database connection: $e');
        rethrow;
      }
    } else {
      print('Database already connected.');
    }
  }

  Future<void> close() async {
    // Check if connection is not closed using the 3.x.x API
    if (_connection != null && !_connection!.isClosed) { // Using isClosed
      await _connection!.close();
      print('Database connection closed.');
    }
    _connection = null; // Clear connection object after closing
  }

  PostgreSQLConnection get connection {
    // Ensure connection is not null and is ready using the 3.x.x API
    if (_connection == null || !_connection!.isReady) { // Using isReady
      throw StateError('Database connection is not open or not ready. Call open() first.');
    }
    return _connection!;
  }
}