import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'message': 'Method Not Allowed'},
    );
  }

  // Validate that 'id' (publisherId) is a valid integer
  final publisherId = int.tryParse(id);
  if (publisherId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Invalid publisher ID format.'},
    );
  }

  final database = context.read<AppDatabase>();
  try {
    // Query to get all books by a specific publisher
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "Title", "Type", "Price", "PubId", "AuthorId" FROM "Book" WHERE "PubId" = @publisherId;',
      substitutionValues: {'publisherId': publisherId},
    );

    if (results.isEmpty) {
      // It's okay if no books are found for a publisher, return an empty list
      return Response.json(
        body: {'message': 'No books found for this publisher.', 'books': []},
      );
    }

    final books = results.map((row) => {
          'id': row[0],
          'title': row[1],
          'type': row[2],
          'price': row[3],
          'pubId': row[4],
          'authorId': row[5],
        },).toList();

    return Response.json(
      body: {'books': books},
    );
  } catch (e) {
    print('Error fetching books by publisher ID: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching books by publisher.'},
    );
  }
}