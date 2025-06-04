// routes/auth/login.dart
import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:postgres/postgres.dart'; // Keep this import for PostgreSQLException

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'message': 'Method Not Allowed'},
    );
  }
  return _login(context);
}

Future<Response> _login(RequestContext context) async {
  final database = context.read<AppDatabase>();
  final env = context.read<DotEnv>();
  final jwtSecret = env['JWT_SECRET'];

  if (jwtSecret == null) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'JWT_SECRET environment variable is not configured.'},
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final username = body['username'] as String?;
  final password = body['password'] as String?;

  if (username == null || password == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Username and password are required.'},
    );
  _login(context);
  }

  try {
    // Ensure database connection is open before querying
    await database.open(); // Important: Open the connection if not already open

    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "Username", "PasswordHash", "IsAdmin" FROM "User" WHERE "Username" = @username;',
      substitutionValues: {'username': username},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Invalid username or password.'},
      );
    }

    final userRow = results.first;
    final int userId = userRow[0];
    final String storedPasswordHash = userRow[2];
    final bool isAdmin = userRow[3];

    // Assuming password hashing is done correctly elsewhere for comparison
    // For now, directly compare. In production, use bcrypt or similar.
    if (password != storedPasswordHash) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Invalid username or password.'},
      );
    }

    // Generate JWT
    final jwt = JWT(
      {
        'userId': userId,
        'username': username,
        'isAdmin': isAdmin,
      },
      // Pass JWTHeader explicitly for issuer and audience in dart_jsonwebtoken 2.x
      header: JWTHeader(
        issuer: 'e-library-api',
        audience: ['e-library-frontend'], // Audience is typically a List<String>
      ),
    );

    final token = jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: const Duration(hours: 1),
    );

    return Response.json(
      body: {'message': 'Login successful!', 'token': token},
    );
  } on PostgreSQLException catch (e) {
    print('Database error during login: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Database error during login.'},
    );
  } catch (e) {
    print('Error during login: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An unexpected error occurred during login.'},
    );
  } finally {
    await database.close(); // Close the connection after the operation
  }
}