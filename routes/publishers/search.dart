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
  return _searchPublishersByName(context);
}

// GET /publishers/search?name={name} - Searches for publishers by name or city
Future<Response> _searchPublishersByName(RequestContext context) async {
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
    // Search in both PName and City using ILIKE for case-insensitive matching
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "PName", "City" FROM "Publisher" WHERE "PName" ILIKE @namePattern OR "City" ILIKE @namePattern;',
      substitutionValues: {'namePattern': '%$name%'},
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
    print('Error searching publishers by name: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while searching for publishers.'},
    );
  }
}