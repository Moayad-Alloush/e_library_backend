import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'message': 'Method Not Allowed'},
    );
  }
  return _searchBooksByTitle(context);
}

// GET /books/search?title={title} - Searches for books by title
Future<Response> _searchBooksByTitle(RequestContext context) async {
  final queryParams = context.request.url.queryParameters;
  final title = queryParams['title'];

  if (title == null || title.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'A "title" query parameter is required for search.'},
    );
  }

  final database = context.read<AppDatabase>();
  try {
    // Use ILIKE for case-insensitive matching in PostgreSQL
    // The % wildcard allows for partial matches at the beginning and end
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "Title", "Type", "Price", "PubId", "AuthorId" FROM "Book" WHERE "Title" ILIKE @titlePattern;',
      substitutionValues: {'titlePattern': '%$title%'},
    );

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
    print('Error searching books by title: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while searching for books.'},
    );
  }
}