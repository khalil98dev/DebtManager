import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Design System Tokens', () {
    test('AppSpacing follows 8pt matrix rhythm', () {
      expect(AppSpacing.xxs, 4.0);
      expect(AppSpacing.xs, 8.0);
      expect(AppSpacing.sm, 12.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.minTouchTarget, greaterThanOrEqualTo(44.0));
    });

    test('AppRadii has proper values', () {
      expect(AppRadii.xs, 6.0);
      expect(AppRadii.sm, 10.0);
      expect(AppRadii.md, 14.0);
      expect(AppRadii.lg, 18.0);
      expect(AppRadii.pill, 999.0);
    });

    test('AppTheme light and dark cupertino themes instantiate correctly', () {
      expect(AppTheme.cupertinoLight.brightness, Brightness.light);
      expect(AppTheme.cupertinoDark.brightness, Brightness.dark);
      expect(AppTheme.materialLight.brightness, Brightness.light);
      expect(AppTheme.materialDark.brightness, Brightness.dark);
    });

    test('AppTypography tabular applies tabularFigures font feature', () {
      const base = TextStyle(fontSize: 16);
      final tabular = AppTypography.tabular(base);
      expect(tabular.fontFeatures, isNotNull);
      expect(tabular.fontFeatures!.any((f) => f.feature == 'tnum'), isTrue);
    });
  });
}
