import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:synco/synco.dart';

import 'settings_state.dart';

/// ViewModel managing user settings, preferences, and database diagnostics.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this.clientRepository,
    required this.invoiceRepository,
    required this.paymentRepository,
    this.paymentAllocationRepository,
    SyncOutboxRepository? outboxRepository,
    SyncOutboxRepository? syncOutboxRepository,
    ThemeMode initialThemeMode = ThemeMode.system,
    Currency initialCurrency = Currency.dzd,
    this.themeModeNotifier,
    this.currencyNotifier,
  }) : outboxRepository = (outboxRepository ?? syncOutboxRepository)!,
       _state = SettingsViewState(
         themeMode: themeModeNotifier?.value ?? initialThemeMode,
         primaryCurrency: currencyNotifier?.value ?? initialCurrency,
       );

  final ClientRepository clientRepository;
  final InvoiceRepository invoiceRepository;
  final PaymentRepository paymentRepository;
  final PaymentAllocationRepository? paymentAllocationRepository;
  final SyncOutboxRepository outboxRepository;
  final ValueNotifier<ThemeMode>? themeModeNotifier;
  final ValueNotifier<Currency>? currencyNotifier;

  SettingsViewState _state;
  SettingsViewState get state => _state;

  Future<void> loadStats() => loadDiagnostics();

  void setThemeMode(ThemeMode mode) {
    if (_state.themeMode == mode) return;
    _state = _state.copyWith(themeMode: mode);
    themeModeNotifier?.value = mode;
    notifyListeners();
  }

  void setPrimaryCurrency(Currency currency) {
    if (_state.primaryCurrency == currency) return;
    _state = _state.copyWith(primaryCurrency: currency);
    currencyNotifier?.value = currency;
    notifyListeners();
  }

  Future<void> loadDiagnostics() async {
    _state = _state.copyWith(
      status: SettingsLoadStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final clients = await clientRepository.getAll();
      final invoices = await invoiceRepository.getAll();
      final payments = await paymentRepository.getAll();
      final allocations = paymentAllocationRepository != null
          ? await paymentAllocationRepository!.getAll()
          : const <PaymentAllocation>[];
      final pendingOps = await outboxRepository.getPending();
      final ackOps = await outboxRepository.getByStatus(
        SyncStatus.acknowledged,
      );
      final failedOps = await outboxRepository.getByStatus(SyncStatus.failed);

      final stats = DatabaseStats(
        clientCount: clients.length,
        invoiceCount: invoices.length,
        paymentCount: payments.length,
        allocationCount: allocations.length,
        outboxCount: pendingOps.length + ackOps.length + failedOps.length,
        schemaVersion: 3,
        storageEngine: 'SQLite + Drift',
      );

      _state = _state.copyWith(
        status: SettingsLoadStatus.loaded,
        databaseStats: stats,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: SettingsLoadStatus.error,
        errorMessage: 'Failed to inspect local database diagnostics: $e',
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => loadDiagnostics();
}
