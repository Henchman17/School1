import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseConnection {
  static final DatabaseConnection _instance = DatabaseConnection._internal();
  late final Connection _connection;
  bool _isInitialized = false;

  factory DatabaseConnection() {
    return _instance;
  }

  DatabaseConnection._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Use environment variable or default to Supabase direct connection
    //final dbHost = Platform.environment['DB_HOST'] ?? 'tajmifkqcttcrhmmiobe.supabase.co';

    _connection = await Connection.open(
      Endpoint(
        host: 'aws-1-ap-southeast-1.pooler.supabase.com',
        port: 5432,
        database: 'guidance',
        username: 'postgres.tajmifkqcttcrhmmiobe',
        password: 'plspguidance2025',
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.require, // Supabase requires SSL
      ),
    );

    _isInitialized = true;
    print('Database connection initialized successfully.');
  }

  Future<Result> query(String sql, [Map<String, dynamic>? values]) async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _connection.execute(
      Sql.named(sql),
      parameters: values,
    );
  }

  Future<int> execute(String sql, [Map<String, dynamic>? values]) async {
    if (!_isInitialized) {
      await initialize();
    }
    final result = await _connection.execute(
      Sql.named(sql),
      parameters: values,
    );
    return result.affectedRows;
  }

  // Transaction wrapper for atomic operations - KEY FIX FOR LAG
  Future<T> transaction<T>(Future<T> Function(TxSession) operation) async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _connection.runTx(operation);
  }

  Future<void> close() async {
    if (_isInitialized) {
      await _connection.close();
      _isInitialized = false;
    }
  }

  bool get isConnected => _isInitialized;
}
