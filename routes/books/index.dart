import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getAllBooks(context);
    case HttpMethod.post:
      return _createBook(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

// GET /books - Fetches all books
Future<Response> _getAllBooks(RequestContext context) async {
  final database = context.read<AppDatabase>();
  try {
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "Title", "Type", "Price", "PubId", "AuthorId" FROM "Book";',
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
    print('Error fetching books: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching books.'},
    );
  }
}

// POST /books - Creates a new book
Future<Response> _createBook(RequestContext context) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  // Check if user is authenticated and is an admin
  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden, // 403 Forbidden
      body: {'message': 'Admin access required to create a book.'},
    );
  }

  final database = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;

  final title = body['title'] as String?;
  final type = body['type'] as String?;
  final price = body['price'] as num?; // Use num to handle int or double
  final pubId = body['pubId'] as int?; // Assuming PubId is int (BIGINT)
  final authorId = body['authorId'] as int?; // Assuming AuthorId is int (BIGINT)

  // Basic validation for required fields
  if (title == null || title.isEmpty ||
      price == null ||
      pubId == null ||
      authorId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Title, price, publisher ID, and author ID are required.'},
    );
  }

  try {
    await database.connection.query(
      'INSERT INTO "Book" ("Title", "Type", "Price", "PubId", "AuthorId") VALUES (@title, @type, @price, @pubId, @authorId);',
      substitutionValues: {
        'title': title,
        'type': type,
        'price': price,
        'pubId': pubId,
        'authorId': authorId,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created, // 201 Created
      body: {'message': 'Book added successfully!'},
    );
  } catch (e) {
    print('Error creating book: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while adding the book.'},
    );
  }
}