import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getAllPublishers(context);
    case HttpMethod.post:
      return _createPublisher(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

// GET /publishers - Fetches all publishers
Future<Response> _getAllPublishers(RequestContext context) async {
  final database = context.read<AppDatabase>();
  try {
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "PName", "City" FROM "Publisher";',
    );

    final publishers = results.map((row) => {
          'id': row[0],
          'pName': row[1],
          'city': row[2],
        },).toList();

    return Response.json(
      body: {'publishers': publishers},
    );
  } catch (e) {
    print('Error fetching publishers: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching publishers.'},
    );
  }
}

// POST /publishers - Creates a new publisher
Future<Response> _createPublisher(RequestContext context) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  // Check if user is authenticated and is an admin
  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden, // 403 Forbidden
      body: {'message': 'Admin access required to create a publisher.'},
    );
  }

  final database = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;

  final pName = body['pName'] as String?;
  final city = body['city'] as String?;

  // Basic validation for required fields
  if (pName == null || pName.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Publisher name is required.'},
    );
  }

  try {
    await database.connection.query(
      'INSERT INTO "Publisher" ("PName", "City") VALUES (@pName, @city);',
      substitutionValues: {
        'pName': pName,
        'city': city,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created, // 201 Created
      body: {'message': 'Publisher added successfully!'},
    );
  } catch (e) {
    print('Error creating publisher: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while adding the publisher.'},
    );
  }
}