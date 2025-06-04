import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getAllAuthors(context);
    case HttpMethod.post:
      return _createAuthor(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

// GET /authors - Fetches all authors
Future<Response> _getAllAuthors(RequestContext context) async {
  final database = context.read<AppDatabase>();
  try {
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "FName", "LName", "Country", "City", "Address" FROM "Author";',
    );

    final authors = results.map((row) => {
          'id': row[0],
          'fName': row[1],
          'lName': row[2],
          'country': row[3],
          'city': row[4],
          'address': row[5],
        },).toList();

    return Response.json(
      body: {'authors': authors},
    );
  } catch (e) {
    print('Error fetching authors: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching authors.'},
    );
  }
}

// POST /authors - Creates a new author
Future<Response> _createAuthor(RequestContext context) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  // Check if user is authenticated and is an admin
  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden, // 403 Forbidden
      body: {'message': 'Admin access required to create an author.'},
    );
  }

  final database = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;

  final fName = body['fName'] as String?;
  final lName = body['lName'] as String?;
  final country = body['country'] as String?;
  final city = body['city'] as String?;
  final address = body['address'] as String?;

  // Basic validation for required fields
  if (fName == null || fName.isEmpty || lName == null || lName.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'First name and last name are required for an author.'},
    );
  }

  try {
    await database.connection.query(
      'INSERT INTO "Author" ("FName", "LName", "Country", "City", "Address") VALUES (@fName, @lName, @country, @city, @address);',
      substitutionValues: {
        'fName': fName,
        'lName': lName,
        'country': country,
        'city': city,
        'address': address,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created, // 201 Created
      body: {'message': 'Author added successfully!'},
    );
  } catch (e) {
    print('Error creating author: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while adding the author.'},
    );
  }
}