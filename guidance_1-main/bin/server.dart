import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../backend/routes/api_routes.dart';
import '../backend/connection.dart';

void main() async {
  final database = DatabaseConnection();
  await database.initialize();
  
  final apiRoutes = ApiRoutes(database);
  
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(apiRoutes.router.call);

  final server = await shelf_io.serve(
    handler,
    '0.0.0.0', // Listen on all interfaces
    8080,
  );

  print('Server running on ${server.address.host}:${server.port}');
}

Middleware corsMiddleware() {
  return createMiddleware(
    requestHandler: (request) => null,
    responseHandler: (response) => response.change(
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      },
    ),
  );
}
