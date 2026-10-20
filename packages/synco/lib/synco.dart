/// Offline synchronization foundation: domain models, outbox contracts,
/// change tracking, and coordination.
library;

export 'src/coordination/sync_coordinator.dart';
export 'src/models/sync_acknowledgement.dart';
export 'src/models/sync_batch_request.dart';
export 'src/models/sync_batch_response.dart';
export 'src/models/sync_conflict.dart';
export 'src/models/sync_entity_type.dart';
export 'src/models/sync_operation.dart';
export 'src/models/sync_operation_id.dart';
export 'src/models/sync_operation_type.dart';
export 'src/models/sync_status.dart';
export 'src/repositories/sync_outbox_repository.dart';
export 'src/repositories/sync_unit_of_work.dart';
export 'src/tracking/sync_change_tracker.dart';
