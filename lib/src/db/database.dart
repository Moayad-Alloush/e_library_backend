// lib/src/db/database.dart
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart'; // <<< This import is critical for PostgreSQLConnection and ConnectionState

/// Manages the PostgreSQL database connection for the application.
class AppDatabase { // Corrected class name

  /// Creates an [AppDatabase] instance.
  AppDatabase({
    required DotEnv env,
  }) : _env = env;
  final DotEnv _env;

  PostgreSQLConnection? _connection;


  /// Opens the database connection.
  ///
  /// It checks if a connection already exists and is ready; if not,
  /// it initializes and opens a new one using environment variables.
  Future<void> open() async {
    // Check connectionState. If null or not ready, create and open.
    if (_connection == null ||
        _connection!.connectionState != ConnectionState.ready) { // Corrected enum name
      final host = _env['DB_HOST'] ?? 'localhost';
      final port = int.tryParse(_env['DB_PORT'] ?? '') ?? 5432;
      final databaseName = _env['DB_NAME'] ?? 'your_database_name';
      final username = _env['DB_USER'] ?? 'postgres';
      final password = _env['DB_PASSWORD'] ?? 'password';

      _connection = PostgreSQLConnection( // Corrected constructor call
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

  /// Closes the database connection if it's open.
  Future<void> close() async {
    // Check if connectionState is not closed before attempting to close
    if (_connection != null &&
        _connection!.connectionState != ConnectionState.closed) { // Corrected enum name
      await _connection!.close();
      print('Database connection closed.');
    }
    _connection = null; // Clear connection object after closing
  }

  /// Provides the active [PostgreSQLConnection] instance.
  ///
  /// Throws a [StateError] if the connection is not open or not ready.
  PostgreSQLConnection get connection { // Corrected class name
    // Ensure connection is not null and is ready before returning
    if (_connection == null ||
        _connection!.connectionState != ConnectionState.ready) { // Corrected enum name
      throw StateError('Database connection is not open or not ready. '
          'Call open() first.');
    }
    return _connection!;
  }
}