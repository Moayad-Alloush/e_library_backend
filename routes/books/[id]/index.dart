import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser
Future<Response> onRequest(RequestContext context, String id) async {
  // Validate that 'id' is a valid integer (BIGSERIAL in DB)
  final bookId = int.tryParse(id);
  if (bookId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Invalid book ID format.'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getBookById(context, bookId);
    case HttpMethod.put:
      return _updateBook(context, bookId);
    case HttpMethod.delete:
      return _deleteBook(context, bookId);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

// GET /books/{id} - Fetches a single book by ID
Future<Response> _getBookById(RequestContext context, int bookId) async {
  final database = context.read<AppDatabase>();
  try {
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "Title", "Type", "Price", "PubId", "AuthorId" FROM "Book" WHERE "Id" = @id;',
      substitutionValues: {'id': bookId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Book not found.'},
      );
    }

    final row = results.first;
    final book = {
      'id': row[0],
      'title': row[1],
      'type': row[2],
      'price': row[3],
      'pubId': row[4],
      'authorId': row[5],
    };

    return Response.json(
      body: {'book': book},
    );
  } catch (e) {
    print('Error fetching book by ID: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching the book.'},
    );
  }
}

// PUT /books/{id} - Updates an existing book by ID
Future<Response> _updateBook(RequestContext context, int bookId) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required to update a book.'},
    );
  }

  final database = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;

  final title = body['title'] as String?;
  final type = body['type'] as String?;
  final price = body['price'] as num?;
  final pubId = body['pubId'] as int?;
  final authorId = body['authorId'] as int?;

  // Ensure at least one field for update is provided
  if (title == null && type == null && price == null && pubId == null && authorId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'At least one field (title, type, price, pubId, authorId) must be provided for update.'},
    );
  }

  // Build the SQL UPDATE statement dynamically
  final setClauses = <String>[];
  final substitutionValues = <String, dynamic>{'id': bookId};

  if (title != null) {
    setClauses.add('"Title" = @title');
    substitutionValues['title'] = title;
  }
  if (type != null) {
    setClauses.add('"Type" = @type');
    substitutionValues['type'] = type;
  }
  if (price != null) {
    setClauses.add('"Price" = @price');
    substitutionValues['price'] = price;
  }
  if (pubId != null) {
    setClauses.add('"PubId" = @pubId');
    substitutionValues['pubId'] = pubId;
  }
  if (authorId != null) {
    setClauses.add('"AuthorId" = @authorId');
    substitutionValues['authorId'] = authorId;
  }

  if (setClauses.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'No valid fields provided for update.'},
    );
  }

  try {
    final updateSql = 'UPDATE "Book" SET ${setClauses.join(', ')} WHERE "Id" = @id;';
    final rowsAffected = await database.connection.execute(
      updateSql,
      substitutionValues: substitutionValues,
    );

    if (rowsAffected == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Book not found for update.'},
      );
    }

    return Response.json(
      body: {'message': 'Book updated successfully!'},
    );
  } catch (e) {
    print('Error updating book: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while updating the book.'},
    );
  }
}

// DELETE /books/{id} - Deletes a book by ID
Future<Response> _deleteBook(RequestContext context, int bookId) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required to delete a book.'},
    );
  }

  final database = context.read<AppDatabase>();
  try {
    final rowsAffected = await database.connection.execute(
      'DELETE FROM "Book" WHERE "Id" = @id;',
      substitutionValues: {'id': bookId},
    );

    if (rowsAffected == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Book not found for deletion.'},
      );
    }

    return Response.json(
      statusCode: HttpStatus.noContent, // 204 No Content
      body: {'message': 'Book deleted successfully!'},
    );
  } catch (e) {
    print('Error deleting book: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while deleting the book.'},
    );
  }
}