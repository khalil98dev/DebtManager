import 'package:application/application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result & Failure Convention', () {
    test('Success holds data, reports isSuccess, and matches when', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.failureOrNull, isNull);

      final matched = result.when(
        success: (data) => 'success:$data',
        failure: (f) => 'failure:${f.message}',
      );
      expect(matched, 'success:42');
    });

    test(
      'FailureResult holds failure, reports isFailure, and matches when',
      () {
        const failure = ValidationFailure(message: 'Invalid input');
        const result = Result<int>.failure(failure);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.dataOrNull, isNull);
        expect(result.failureOrNull, failure);

        final matched = result.when(
          success: (data) => 'success:$data',
          failure: (f) => 'failure:${f.message}',
        );
        expect(matched, 'failure:Invalid input');
      },
    );

    test('Success equality and string representation', () {
      const res1 = Result<String>.success('item');
      const res2 = Result<String>.success('item');
      const res3 = Result<String>.success('other');

      expect(res1, equals(res2));
      expect(res1.hashCode, equals(res2.hashCode));
      expect(res1, isNot(equals(res3)));
      expect(res1.toString(), 'Result.success(item)');
    });

    test('FailureResult equality and string representation', () {
      const res1 = Result<int>.failure(ConflictFailure(message: 'conflict'));
      const res2 = Result<int>.failure(ConflictFailure(message: 'conflict'));
      const res3 = Result<int>.failure(ConflictFailure(message: 'different'));

      expect(res1, equals(res2));
      expect(res1.hashCode, equals(res2.hashCode));
      expect(res1, isNot(equals(res3)));
      expect(res1.toString(), contains('Result.failure(ConflictFailure'));
    });

    test('NotFoundFailure encapsulates entityType and entityId', () {
      const failure = NotFoundFailure(
        message: 'Client not found',
        entityType: 'Client',
        entityId: 'id-123',
      );

      expect(failure.message, 'Client not found');
      expect(failure.entityType, 'Client');
      expect(failure.entityId, 'id-123');
      expect(failure.toString(), contains('NotFoundFailure'));
    });

    test('RepositoryFailure captures underlying cause', () {
      final cause = Exception('Disk full');
      final failure = RepositoryFailure(
        message: 'Persistence write failed',
        cause: cause,
      );

      expect(failure.message, 'Persistence write failed');
      expect(failure.cause, cause);
    });
  });
}
