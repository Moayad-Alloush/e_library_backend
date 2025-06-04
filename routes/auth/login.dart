// routes/auth/login.dart
import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:postgres/postgres.dart'; // For PgException
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; // For JWT
import 'package:dotenv/dotenv.dart'; // For JWT secret

FutureOr<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'message': 'Method Not Allowed'},
    );
  }

  final body = await context.request.json();
  final username = body['username'] as String?;
  final password = body['password'] as String?;

  if (username == null || password == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Username and password are required.'},
    );
  }

  final database = context.read<AppDatabase>();
  final conn = database.connection;
  final env = context.read<DotEnv>(); // Access DotEnv via context

  try {
    // 1. Find user by username
    final result = await conn.query(
      'SELECT id, username, password_hash, is_admin FROM users WHERE username = @username',
      variables: {'username': username},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Invalid credentials.'},
      );
    }

    final userRow = result.first;
    final storedPasswordHash = userRow[2] as String; // Assuming password_hash is at index 2
    final userId = userRow[0] as String; // Assuming id is at index 0
    final isAdmin = userRow[3] as bool; // Assuming is_admin is at index 3

    // 2. Verify password (simple check for now, you should hash and compare securely)
    if (password != storedPasswordHash) { // In a real app, use a strong hashing library like bcrypt
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Invalid credentials.'},
      );
    }

    // 3. Generate JWT token
    final jwt = JWT(
      {
        'userId': userId,
        'username': username,
        'isAdmin': isAdmin,
      },
    );

    // Get your JWT secret from environment variables
    final jwtSecret = env['JWT_SECRET'];
    if (jwtSecret == null) {
      print('JWT_SECRET environment variable not set!');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Server configuration error.'},
      );
    }

    final token = jwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(hours: 1)); // Token expires in 1 hour

    return Response.json(
      body: {
        'message': 'Login successful!',
        'token': token,
        'userId': userId,
        'isAdmin': isAdmin,
      },
    );
  } on PgException catch (e) {
    print('Database error during login: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Database error during login.'},
    );
  } catch (e) {
    print('Unexpected error during login: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An unexpected error occurred.'},
    );
  }
}