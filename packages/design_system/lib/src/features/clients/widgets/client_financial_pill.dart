import 'package:domain/domain.dart';
import 'package:flutter/cupertino.dart';

import '../../../components/surfaces/app_badge.dart';

/// Renders a financial status pill for a client when financial metrics are known.
class ClientFinancialPill extends StatelessWidget {
  const ClientFinancialPill({super.key, required this.position});

  final ClientFinancialPosition? position;

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return const SizedBox.shrink();
    }

    final pos = position!;

    if (pos.hasOutstandingDebt) {
      return AppBadge(
        label: 'Debt: ${pos.outstandingDebt.format()}',
        variant: AppBadgeVariant.destructive,
        showDot: true,
      );
    }

    if (pos.hasUnallocatedCredit) {
      return AppBadge(
        label: 'Credit: ${pos.unallocatedCredit.format()}',
        variant: AppBadgeVariant.success,
        showDot: true,
      );
    }

    return const AppBadge(label: 'Settled', variant: AppBadgeVariant.neutral);
  }
}
