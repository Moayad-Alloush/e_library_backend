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
  return _searchAuthorsByName(context);
}

// GET /authors/search?name={name} - Searches for authors by first or last name
Future<Response> _searchAuthorsByName(RequestContext context) async {
  final queryParams = context.request.url.queryParameters;
  final name = queryParams['name'];

  if (name == null || name.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'A "name" query parameter is required for search.'},
    );
  }

  final database = context.read<AppDatabase>();
  try {
    // Search in both FName and LName using ILIKE for case-insensitive matching
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "FName", "LName", "Country", "City", "Address" FROM "Author" WHERE "FName" ILIKE @namePattern OR "LName" ILIKE @namePattern;',
      substitutionValues: {'namePattern': '%$name%'},
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
    print('Error searching authors by name: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while searching for authors.'},
    );
  }
}