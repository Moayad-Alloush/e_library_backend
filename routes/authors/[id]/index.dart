import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser
Future<Response> onRequest(RequestContext context, String id) async {
  // Validate that 'id' is a valid integer (BIGSERIAL in DB)
  final authorId = int.tryParse(id);
  if (authorId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Invalid author ID format.'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getAuthorById(context, authorId);
    case HttpMethod.put:
      return _updateAuthor(context, authorId);
    case HttpMethod.delete:
      return _deleteAuthor(context, authorId);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

// GET /authors/{id} - Fetches a single author by ID
Future<Response> _getAuthorById(RequestContext context, int authorId) async {
  final database = context.read<AppDatabase>();
  try {
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "FName", "LName", "Country", "City", "Address" FROM "Author" WHERE "Id" = @id;',
      substitutionValues: {'id': authorId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Author not found.'},
      );
    }

    final row = results.first;
    final author = {
      'id': row[0],
      'fName': row[1],
      'lName': row[2],
      'country': row[3],
      'city': row[4],
      'address': row[5],
    };

    return Response.json(
      body: {'author': author},
    );
  } catch (e) {
    print('Error fetching author by ID: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching the author.'},
    );
  }
}

// PUT /authors/{id} - Updates an existing author by ID
Future<Response> _updateAuthor(RequestContext context, int authorId) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required to update an author.'},
    );
  }

  final database = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;

  final fName = body['fName'] as String?;
  final lName = body['lName'] as String?;
  final country = body['country'] as String?;
  final city = body['city'] as String?;
  final address = body['address'] as String?;

  // Ensure at least one field for update is provided
  if (fName == null && lName == null && country == null && city == null && address == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'At least one field (fName, lName, country, city, address) must be provided for update.'},
    );
  }

  // Build the SQL UPDATE statement dynamically
  final setClauses = <String>[];
  final substitutionValues = <String, dynamic>{'id': authorId};

  if (fName != null) {
    setClauses.add('"FName" = @fName');
    substitutionValues['fName'] = fName;
  }
  if (lName != null) {
    setClauses.add('"LName" = @lName');
    substitutionValues['lName'] = lName;
  }
  if (country != null) {
    setClauses.add('"Country" = @country');
    substitutionValues['country'] = country;
  }
  if (city != null) {
    setClauses.add('"City" = @city');
    substitutionValues['city'] = city;
  }
  if (address != null) {
    setClauses.add('"Address" = @address');
    substitutionValues['address'] = address;
  }

  if (setClauses.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'No valid fields provided for update.'},
    );
  }

  try {
    final updateSql = 'UPDATE "Author" SET ${setClauses.join(', ')} WHERE "Id" = @id;';
    final rowsAffected = await database.connection.execute(
      updateSql,
      substitutionValues: substitutionValues,
    );

    if (rowsAffected == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Author not found for update.'},
      );
    }

    return Response.json(
      body: {'message': 'Author updated successfully!'},
    );
  } catch (e) {
    print('Error updating author: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while updating the author.'},
    );
  }
}

// DELETE /authors/{id} - Deletes an author by ID
Future<Response> _deleteAuthor(RequestContext context, int authorId) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required to delete an author.'},
    );
  }

  final database = context.read<AppDatabase>();
  try {
    final rowsAffected = await database.connection.execute(
      'DELETE FROM "Author" WHERE "Id" = @id;',
      substitutionValues: {'id': authorId},
    );

    if (rowsAffected == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Author not found for deletion.'},
      );
    }

    return Response.json(
      statusCode: HttpStatus.noContent, // 204 No Content
      body: {'message': 'Author deleted successfully!'},
    );
  } catch (e) {
    print('Error deleting author: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while deleting the author.'},
    );
  }
}