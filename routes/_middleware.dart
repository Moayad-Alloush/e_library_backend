// routes/_middleware.dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser

Handler middleware(Handler handler) {
  return (context) async {
    final env = context.read<DotEnv>();
    final jwtSecret = env['JWT_SECRET'];

    if (jwtSecret == null) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'JWT_SECRET environment variable is not configured.'},
      );
    }

    // Public routes that don't require authentication.
    if (context.request.uri.path.startsWith('/auth/login') ||
        context.request.uri.path.startsWith('/auth/signup') ||
        (context.request.method == HttpMethod.get &&
            (context.request.uri.path.startsWith('/books') ||
                context.request.uri.path.startsWith('/authors') ||
                context.request.uri.path.startsWith('/publishers')))
        ) {
      return handler(context);
    }

    final authHeader = context.request.headers['authorization'];
    String? token;

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      token = authHeader.substring(7);
    }

    if (token == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Authentication required. Token missing.'},
      );
    }

    try {
      // Corrected: Use the static JWT.verify method to verify the token
      final verifiedJwt = JWT.verify(token, SecretKey(jwtSecret));

      // Extract claims from the verified token's payload
      final payload = verifiedJwt.payload as Map<String, dynamic>;
      final userId = payload['userId'] as int?;
      final isAdmin = payload['isAdmin'] as bool? ?? false;

      if (userId == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'message': 'Invalid token payload: userId missing.'},
        );
      }

      final authenticatedUser = AuthenticatedUser(
        userId: userId,
        isAdmin: isAdmin,
      );

      final newContext = context.provide<AuthenticatedUser>(
        () => authenticatedUser,
      );

      return handler(newContext);
    } on JWTExpiredException {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Token expired.'},
      );
    } on JWTInvalidException {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Invalid token.'},
      );
    } on JWTUndefinedException {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'message': 'Token undefined.'},
      );
    } catch (e) {
      print('JWT verification error: $e');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'message': 'Failed to authenticate token.'},
      );
    }
  };
}