import 'package:application/application.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_repositories.dart';

void main() {
  group('GetInvoiceById Query', () {
    late InMemoryInvoiceRepository invoiceRepo;
    late GetInvoiceById getInvoiceById;

    setUp(() {
      invoiceRepo = InMemoryInvoiceRepository();
      getInvoiceById = GetInvoiceById(invoiceRepo);
    });

    test('returns invoice when found', () async {
      final invoice = Invoice.draft(
        clientId: ClientId.generate(),
        number: 'INV-100',
      );
      await invoiceRepo.add(invoice);

      final result = await getInvoiceById.execute(
        GetInvoiceByIdQuery(invoice.id),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(invoice));
    });

    test('returns NotFoundFailure when invoice does not exist', () async {
      final nonExistentId = InvoiceId.generate();

      final result = await getInvoiceById.execute(
        GetInvoiceByIdQuery(nonExistentId),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      final nf = result.failureOrNull! as NotFoundFailure;
      expect(nf.entityType, equals('Invoice'));
      expect(nf.entityId, equals(nonExistentId));
    });
  });
}
