import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

enum SettingsLoadStatus { initial, loading, loaded, error }

/// Diagnostics metrics for local SQLite database.
@immutable
class DatabaseStats {
  const DatabaseStats({
    this.clientCount = 0,
    this.invoiceCount = 0,
    this.paymentCount = 0,
    this.allocationCount = 0,
    this.outboxCount = 0,
    this.schemaVersion = 3,
    this.storageEngine = 'SQLite + Drift',
  });

  final int clientCount;
  final int invoiceCount;
  final int paymentCount;
  final int allocationCount;
  final int outboxCount;
  final int schemaVersion;
  final String storageEngine;
}

/// Immutable state for the application settings and preferences screen.
@immutable
class SettingsViewState {
  const SettingsViewState({
    this.status = SettingsLoadStatus.initial,
    this.themeMode = ThemeMode.system,
    this.primaryCurrency = Currency.dzd,
    this.databaseStats = const DatabaseStats(),
    this.errorMessage,
  });

  final SettingsLoadStatus status;
  final ThemeMode themeMode;
  final Currency primaryCurrency;
  final DatabaseStats databaseStats;
  final String? errorMessage;

  bool get isLoading => status == SettingsLoadStatus.loading;

  SettingsViewState copyWith({
    SettingsLoadStatus? status,
    ThemeMode? themeMode,
    Currency? primaryCurrency,
    DatabaseStats? databaseStats,
    String? errorMessage,
  }) {
    return SettingsViewState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      databaseStats: databaseStats ?? this.databaseStats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
