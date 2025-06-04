// lib/main.dart
import 'dart:io'; // Keep this for InternetAddress, though not used in the init body for local setup
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart'; // Import dotenv
import 'package:e_library_backend/src/db/database.dart'; // Import your AppDatabase

// Declare env globally so it can be accessed in init and onRequest
late final DotEnv env;
// Declare the database instance globally so it can be initialized once
// and then provided as a singleton.
late final AppDatabase database;

// This function runs once when your Dart Frog server starts
Future<void> init(InternetAddress ip, int port) async {
  // Initialize and load DotEnv
  // Ensure your .env file is in the root of your project
  env = DotEnv(includePlatformEnvironment: true)..load();
  print('Environment variables loaded.'); // Added for debug

  // Initialize your database (once)
  database = AppDatabase(env: env); // Pass env to the database constructor
  await database.open(); // Open the database connection
  print('Database connection initialized and opened.'); // Added for debug

  // The Response.json(body: {'message': 'Server started!'}); line was removed
  // as it doesn't serve a functional purpose in the init hook.
  // Responses are handled by specific routes.
}

// This handler is called for every incoming request.
// It's where you can provide dependencies to the request context.
Handler onRequest(Handler handler) {
  // Provide the *single, already initialized* AppDatabase instance to the context.
  // Routes can then access it using `context.read<AppDatabase>()`.
  return handler
      .use(provider<AppDatabase>((context) => database))
      // Provide the DotEnv instance to the context.
      // Routes can then access it using `context.read<DotEnv>()`.
      .use(provider<DotEnv>((context) => env));
}