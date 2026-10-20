import 'package:domain/domain.dart';

/// Query input for retrieving the global dashboard summary.
final class GetDashboardSummaryQuery {
  const GetDashboardSummaryQuery({this.currency});

  final Currency? currency;
}
