import 'package:application/application.dart';
import 'package:flutter/foundation.dart';

enum DashboardStatus { initial, loading, loaded, error }

@immutable
class DashboardViewState {
  const DashboardViewState({
    this.status = DashboardStatus.initial,
    this.summary,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardSummary? summary;
  final String? errorMessage;

  bool get isLoading => status == DashboardStatus.loading && summary == null;
  bool get isRefreshing => status == DashboardStatus.loading && summary != null;
  bool get isLoaded => status == DashboardStatus.loaded;
  bool get hasError => status == DashboardStatus.error;

  DashboardViewState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    String? errorMessage,
  }) {
    return DashboardViewState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardViewState &&
          other.status == status &&
          other.summary == summary &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, summary, errorMessage);
}
