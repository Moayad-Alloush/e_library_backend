// routes/auth/signup.dart
import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:e_library_backend/src/db/database.dart';
// Ensure this import is present for PostgreSQLException

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'message': 'Method Not Allowed'},
    );
  }
  return _signup(context);
}

Future<Response> _signup(RequestContext context) async {
  final database = context.read<AppDatabase>();
  final env = context.read<DotEnv>();
  final jwtSecret = env['JWT_SECRET']; // Access env for secret if needed (though not strictly for signup)

  if (jwtSecret == null) {
    print('Warning: JWT_SECRET environment variable is not configured.');
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final username = body['username'] as String?;
  final password = body['password'] as String?;
  final isAdmin = body['isAdmin'] as bool? ?? false;

  if (username == null || password == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Username and password are required.'},
    );
  }

  try {
    final existingUsers = await database.connection.query(
      'SELECT "Id" FROM "User" WHERE "Username" = @username;',
      substitutionValues: {'username': username},
    );

    if (existingUsers.isNotEmpty) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'message': 'User with this username already exists.'},
      );
    }

    final passwordHash = password;

    await database.connection.query(
      'INSERT INTO "User" ("Username", "PasswordHash", "IsAdmin") VALUES (@username, @passwordHash, @isAdmin);',
      substitutionValues: {
        'username': username,
        'passwordHash': passwordHash,
        'isAdmin': isAdmin,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'message': 'User registered successfully!'},
    );
  } on PostgreSQLException catch (e) { // Ensure PostgreSQLException is recognized
    print('Database error during signup: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Database error during signup.'},
    );
  } catch (e) {
    print('Error during signup: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An unexpected error occurred during signup.'},
    );
  }
}