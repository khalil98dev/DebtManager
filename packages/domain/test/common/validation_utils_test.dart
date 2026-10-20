import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationUtils', () {
    group('validateAndTrimRequired', () {
      test('trims whitespace from valid strings', () {
        expect(
          ValidationUtils.validateAndTrimRequired('   valid text   '),
          equals('valid text'),
        );
      });

      test('rejects empty string with ArgumentError', () {
        expect(
          () => ValidationUtils.validateAndTrimRequired('', name: 'testField'),
          throwsA(
            isA<ArgumentError>().having((e) => e.name, 'name', 'testField'),
          ),
        );
      });

      test(
        'rejects whitespace-only string with ArgumentError and custom message',
        () {
          expect(
            () => ValidationUtils.validateAndTrimRequired(
              '   \t\r\n  ',
              name: 'customField',
              message: 'Custom error message',
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'Custom error message',
              ),
            ),
          );
        },
      );
    });

    group('validateAndTrimNumber', () {
      test('trims and validates valid number strings', () {
        expect(
          ValidationUtils.validateAndTrimNumber('  INV-2026-999  '),
          equals('INV-2026-999'),
        );
      });

      test('rejects empty and whitespace-only number strings', () {
        expect(
          () => ValidationUtils.validateAndTrimNumber(''),
          throwsArgumentError,
        );
        expect(
          () => ValidationUtils.validateAndTrimNumber('   \n  '),
          throwsArgumentError,
        );
      });
    });

    group('normalizeOptionalString', () {
      test('returns null for null inputs', () {
        expect(ValidationUtils.normalizeOptionalString(null), isNull);
      });

      test('returns null for empty strings', () {
        expect(ValidationUtils.normalizeOptionalString(''), isNull);
      });

      test('returns null for whitespace-only strings', () {
        expect(ValidationUtils.normalizeOptionalString('   \t\r\n '), isNull);
      });

      test('returns trimmed string for non-empty text', () {
        expect(
          ValidationUtils.normalizeOptionalString('  Special note  '),
          equals('Special note'),
        );
      });
    });
  });
}
