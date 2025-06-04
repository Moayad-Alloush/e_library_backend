// routes/auth/signup.dart
import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart'; // Ensure this import is here

FutureOr<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'message': 'Method Not Allowed'},
    );
  }

  // Explicitly cast to Map<String, dynamic> to avoid dynamic calls warnings
  final body = await context.request.json() as Map<String, dynamic>;
  final username = body['username'] as String?;
  final password = body['password'] as String?;
  final fName = body['fName'] as String?;
  final lName = body['lName'] as String?;

  if (username == null ||
      password == null ||
      fName == null ||
      lName == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'All fields are required: username, password, '
          'fName, lName.',},
    );
  }

  final database = context.read<AppDatabase>();
  final conn = database.connection;
  const uuid = Uuid(); // Changed from const to final

  try {
    // Check if username already exists
    final existingUser = await conn.query(
      'SELECT id FROM users WHERE username = @username',
      variables: {'username': username},
    );

    if (existingUser.isNotEmpty) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'message': 'Username already taken.'},
      );
    }

    // Hash the password before storing (IMPORTANT: Use a real hashing library
    // like Argon2, Bcrypt in a production app for security)
    final passwordHash = password; // DO NOT USE THIS IN PRODUCTION

    final userId = uuid.v4(); // Generate a unique ID for the new user

    // Insert new user into the database
    await conn.query(
      'INSERT INTO users (id, username, password_hash, f_name, l_name) '
      'VALUES (@id, @username, @password_hash, @f_name, @l_name)',
      variables: {
        'id': userId,
        'username': username,
        'password_hash': passwordHash,
        'f_name': fName,
        'l_name': lName,
        // 'is_admin': false, // No need to explicitly set if default is false
      },
    );

    return Response.json(
      body: {'message': 'User registered successfully!'},
    );
  } on PgException catch (e) {
    print('Database error during signup: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Database error during registration.'},
    );
  } catch (e) {
    print('Unexpected error during signup: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An unexpected error occurred.'},
    );
  }
}