import 'dart:io';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synco/synco.dart';

import 'tables/clients_table.dart';
import 'tables/invoice_lines_table.dart';
import 'tables/invoices_table.dart';
import 'tables/payment_allocations_table.dart';
import 'tables/payments_table.dart';
import 'tables/sync_outbox_table.dart';

part 'app_database.g.dart';

/// Drift database managing local persistent storage for the debt management application.
///
/// Encapsulates SQLite connection management, schema definitions, and migration strategies.
@DriftDatabase(
  tables: [
    ClientsTable,
    InvoicesTable,
    InvoiceLinesTable,
    PaymentsTable,
    PaymentAllocationsTable,
    SyncOutboxTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.defaults({String dbName = 'debt_manager.sqlite'}) {
    return AppDatabase(_openConnection(dbName));
  }

  factory AppDatabase.inMemory({bool logStatements = false}) {
    return AppDatabase(NativeDatabase.memory(logStatements: logStatements));
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS roles (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          permissions_json TEXT NOT NULL,
          is_system INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');
      await customStatement('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT NOT NULL PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          display_name TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          role_id TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');
    },
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(invoicesTable);
        await m.createTable(invoiceLinesTable);
      }
      if (from < 3) {
        await m.createTable(paymentsTable);
        await m.createTable(paymentAllocationsTable);
      }
      if (from < 4) {
        await m.createTable(syncOutboxTable);
      }
    },
  );

  static QueryExecutor _openConnection(String dbName) {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, dbName));
      return NativeDatabase.createInBackground(file);
    });
  }
}
