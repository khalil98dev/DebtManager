import 'package:domain/domain.dart';

import '../models/sync_entity_type.dart';
import '../models/sync_operation.dart';
import '../models/sync_operation_id.dart';
import '../models/sync_operation_type.dart';
import '../models/sync_status.dart';

/// Pure domain change tracker that transforms domain entity modifications into
/// explicit, immutable [SyncOperation] records with deterministic JSON payloads.
abstract final class SyncChangeTracker {
  /// Tracks creation of a [Client] entity.
  static SyncOperation trackClientCreated(
    Client client, {
    required int localSequence,
    SyncOperationId? operationId,
    DateTime? recordedAt,
  }) {
    return SyncOperation(
      id: operationId ?? SyncOperationId.generate(),
      entityType: SyncEntityType.client,
      entityId: client.id.value,
      operationType: SyncOperationType.create,
      status: SyncStatus.pending,
      localSequence: localSequence,
      entityVersion: 1,
      createdAt: recordedAt ?? DateTime.now(),
      payload: {
        'id': client.id.value,
        'name': client.name,
        'phone': client.phone,
        'notes': client.notes,
        'createdAt': client.createdAt.toIso8601String(),
        'updatedAt': client.updatedAt.toIso8601String(),
      },
    );
  }

  /// Tracks an update to an existing [Client] entity.
  static SyncOperation trackClientUpdated(
    Client client, {
    required int localSequence,
    required int entityVersion,
    SyncOperationId? operationId,
    DateTime? recordedAt,
  }) {
    return SyncOperation(
      id: operationId ?? SyncOperationId.generate(),
      entityType: SyncEntityType.client,
      entityId: client.id.value,
      operationType: SyncOperationType.update,
      status: SyncStatus.pending,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: recordedAt ?? DateTime.now(),
      payload: {
        'id': client.id.value,
        'name': client.name,
        'phone': client.phone,
        'notes': client.notes,
        'createdAt': client.createdAt.toIso8601String(),
        'updatedAt': client.updatedAt.toIso8601String(),
      },
    );
  }

  /// Tracks creation of an [Invoice] entity in draft state.
  static SyncOperation trackInvoiceCreated(
    Invoice invoice, {
    required int localSequence,
    SyncOperationId? operationId,
    DateTime? recordedAt,
  }) {
    return SyncOperation(
      id: operationId ?? SyncOperationId.generate(),
      entityType: SyncEntityType.invoice,
      entityId: invoice.id.value,
      operationType: SyncOperationType.create,
      status: SyncStatus.pending,
      localSequence: localSequence,
      entityVersion: 1,
      createdAt: recordedAt ?? DateTime.now(),
      payload: _serializeInvoice(invoice),
    );
  }

  /// Tracks issuance of a finalized [Invoice] entity.
  static SyncOperation trackInvoiceIssued(
    Invoice invoice, {
    required int localSequence,
    required int entityVersion,
    SyncOperationId? operationId,
    DateTime? recordedAt,
  }) {
    return SyncOperation(
      id: operationId ?? SyncOperationId.generate(),
      entityType: SyncEntityType.invoice,
      entityId: invoice.id.value,
      operationType: SyncOperationType.issue,
      status: SyncStatus.pending,
      localSequence: localSequence,
      entityVersion: entityVersion,
      createdAt: recordedAt ?? DateTime.now(),
      payload: _serializeInvoice(invoice),
    );
  }

  /// Tracks recording of a [Payment] entity.
  static SyncOperation trackPaymentRecorded(
    Payment payment, {
    required int localSequence,
    SyncOperationId? operationId,
    DateTime? recordedAt,
  }) {
    return SyncOperation(
      id: operationId ?? SyncOperationId.generate(),
      entityType: SyncEntityType.payment,
      entityId: payment.id.value,
      operationType: SyncOperationType.create,
      status: SyncStatus.pending,
      localSequence: localSequence,
      entityVersion: 1,
      createdAt: recordedAt ?? DateTime.now(),
      payload: {
        'id': payment.id.value,
        'clientId': payment.clientId.value,
        'amount': payment.amount.subunits,
        'currency': payment.currency.code,
        'receivedAt': payment.receivedAt.toIso8601String(),
        'notes': payment.notes,
        'createdAt': payment.createdAt.toIso8601String(),
      },
    );
  }

  /// Tracks recording of a [PaymentAllocation] entity.
  static SyncOperation trackPaymentAllocated(
    PaymentAllocation allocation, {
    required int localSequence,
    SyncOperationId? operationId,
    DateTime? recordedAt,
  }) {
    return SyncOperation(
      id: operationId ?? SyncOperationId.generate(),
      entityType: SyncEntityType.paymentAllocation,
      entityId: allocation.id.value,
      operationType: SyncOperationType.create,
      status: SyncStatus.pending,
      localSequence: localSequence,
      entityVersion: 1,
      createdAt: recordedAt ?? DateTime.now(),
      payload: {
        'id': allocation.id.value,
        'paymentId': allocation.paymentId.value,
        'invoiceId': allocation.invoiceId.value,
        'amount': allocation.amount.subunits,
        'currency': allocation.currency.code,
        'createdAt': allocation.createdAt.toIso8601String(),
      },
    );
  }

  static Map<String, dynamic> _serializeInvoice(Invoice invoice) {
    return {
      'id': invoice.id.value,
      'clientId': invoice.clientId.value,
      'number': invoice.number,
      'status': invoice.status.name,
      'notes': invoice.notes,
      'currency': invoice.currency.code,
      'createdAt': invoice.createdAt.toIso8601String(),
      'issuedAt': invoice.issuedAt?.toIso8601String(),
      'lines': invoice.lines
          .map(
            (l) => {
              'id': l.id.value,
              'description': l.description,
              'quantity': l.quantity,
              'unitPrice': l.unitPrice.subunits,
              'discount': l.discount.subunits,
              'createdAt': l.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };
  }
}
