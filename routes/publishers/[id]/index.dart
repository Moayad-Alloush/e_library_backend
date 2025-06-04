import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:e_library_backend/src/db/database.dart';
import 'package:e_library_backend/src/models/authenticated_user.dart'; // Import AuthenticatedUser
Future<Response> onRequest(RequestContext context, String id) async {
  // Validate that 'id' is a valid integer (BIGSERIAL in DB)
  final publisherId = int.tryParse(id);
  if (publisherId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Invalid publisher ID format.'},
    );
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getPublisherById(context, publisherId);
    case HttpMethod.put:
      return _updatePublisher(context, publisherId);
    case HttpMethod.delete:
      return _deletePublisher(context, publisherId);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

// GET /publishers/{id} - Fetches a single publisher by ID
Future<Response> _getPublisherById(RequestContext context, int publisherId) async {
  final database = context.read<AppDatabase>();
  try {
    final List<List<dynamic>> results = await database.connection.query(
      'SELECT "Id", "PName", "City" FROM "Publisher" WHERE "Id" = @id;',
      substitutionValues: {'id': publisherId},
    );

    if (results.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Publisher not found.'},
      );
    }

    final row = results.first;
    final publisher = {
      'id': row[0],
      'pName': row[1],
      'city': row[2],
    };

    return Response.json(
      body: {'publisher': publisher},
    );
  } catch (e) {
    print('Error fetching publisher by ID: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while fetching the publisher.'},
    );
  }
}

// PUT /publishers/{id} - Updates an existing publisher by ID
Future<Response> _updatePublisher(RequestContext context, int publisherId) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required to update a publisher.'},
    );
  }

  final database = context.read<AppDatabase>();
  final body = await context.request.json() as Map<String, dynamic>;

  final pName = body['pName'] as String?;
  final city = body['city'] as String?;

  // Ensure at least one field for update is provided
  if (pName == null && city == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'At least one field (pName, city) must be provided for update.'},
    );
  }

  // Build the SQL UPDATE statement dynamically
  final setClauses = <String>[];
  final substitutionValues = <String, dynamic>{'id': publisherId};

  if (pName != null) {
    setClauses.add('"PName" = @pName');
    substitutionValues['pName'] = pName;
  }
  if (city != null) {
    setClauses.add('"City" = @city');
    substitutionValues['city'] = city;
  }

  if (setClauses.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'No valid fields provided for update.'},
    );
  }

  try {
    final updateSql = 'UPDATE "Publisher" SET ${setClauses.join(', ')} WHERE "Id" = @id;';
    final rowsAffected = await database.connection.execute(
      updateSql,
      substitutionValues: substitutionValues,
    );

    if (rowsAffected == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Publisher not found for update.'},
      );
    }

    return Response.json(
      body: {'message': 'Publisher updated successfully!'},
    );
  } catch (e) {
    print('Error updating publisher: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while updating the publisher.'},
    );
  }
}

// DELETE /publishers/{id} - Deletes a publisher by ID
Future<Response> _deletePublisher(RequestContext context, int publisherId) async {
  final authenticatedUser = context.read<AuthenticatedUser?>();

  if (authenticatedUser == null || !authenticatedUser.isAdmin) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'message': 'Admin access required to delete a publisher.'},
    );
  }

  final database = context.read<AppDatabase>();
  try {
    final rowsAffected = await database.connection.execute(
      'DELETE FROM "Publisher" WHERE "Id" = @id;',
      substitutionValues: {'id': publisherId},
    );

    if (rowsAffected == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'message': 'Publisher not found for deletion.'},
      );
    }

    return Response.json(
      statusCode: HttpStatus.noContent, // 204 No Content
      body: {'message': 'Publisher deleted successfully!'},
    );
  } catch (e) {
    print('Error deleting publisher: $e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'An error occurred while deleting the publisher.'},
    );
  }
}