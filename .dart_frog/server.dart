// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/publishers/search.dart' as publishers_search;
import '../routes/publishers/index.dart' as publishers_index;
import '../routes/publishers/[id]/index.dart' as publishers_$id_index;
import '../routes/publishers/[id]/books.dart' as publishers_$id_books;
import '../routes/books/search.dart' as books_search;
import '../routes/books/index.dart' as books_index;
import '../routes/books/[id]/index.dart' as books_$id_index;
import '../routes/authors/search.dart' as authors_search;
import '../routes/authors/index.dart' as authors_index;
import '../routes/authors/[id]/index.dart' as authors_$id_index;
import '../routes/authors/[id]/books.dart' as authors_$id_books;
import '../routes/auth/signup.dart' as auth_signup;
import '../routes/auth/login.dart' as auth_login;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/auth', (context) => buildAuthHandler()(context))
    ..mount('/authors/<id>', (context,id,) => buildAuthors$idHandler(id,)(context))
    ..mount('/authors', (context) => buildAuthorsHandler()(context))
    ..mount('/books/<id>', (context,id,) => buildBooks$idHandler(id,)(context))
    ..mount('/books', (context) => buildBooksHandler()(context))
    ..mount('/publishers/<id>', (context,id,) => buildPublishers$idHandler(id,)(context))
    ..mount('/publishers', (context) => buildPublishersHandler()(context))
    ..mount('/', (context) => buildHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/signup', (context) => auth_signup.onRequest(context,))..all('/login', (context) => auth_login.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildAuthors$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => authors_$id_index.onRequest(context,id,))..all('/books', (context) => authors_$id_books.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildAuthorsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/search', (context) => authors_search.onRequest(context,))..all('/', (context) => authors_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildBooks$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => books_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildBooksHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/search', (context) => books_search.onRequest(context,))..all('/', (context) => books_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildPublishers$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => publishers_$id_index.onRequest(context,id,))..all('/books', (context) => publishers_$id_books.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildPublishersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/search', (context) => publishers_search.onRequest(context,))..all('/', (context) => publishers_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

