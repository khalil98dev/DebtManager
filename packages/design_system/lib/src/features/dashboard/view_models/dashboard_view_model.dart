import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'dashboard_state.dart';

/// ViewModel orchestrating the top-level application dashboard.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required this.getDashboardSummary});

  final GetDashboardSummary getDashboardSummary;

  DashboardViewState _state = const DashboardViewState();
  DashboardViewState get state => _state;

  Future<void> loadSummary({Currency? currency}) async {
    _state = _state.copyWith(
      status: DashboardStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    final result = await getDashboardSummary.execute(
      GetDashboardSummaryQuery(currency: currency),
    );

    if (result.isSuccess) {
      _state = _state.copyWith(
        status: DashboardStatus.loaded,
        summary: result.dataOrNull,
      );
    } else {
      _state = _state.copyWith(
        status: DashboardStatus.error,
        errorMessage:
            result.failureOrNull?.message ?? 'Failed to load dashboard.',
      );
    }
    notifyListeners();
  }

  Future<void> refresh({Currency? currency}) => loadSummary(currency: currency);
}
