/// Represents the lifecycle status of an [Invoice].
enum InvoiceStatus {
  /// Initial editable draft status. Lines can be added, updated, or removed.
  draft,

  /// Finalized and legally binding status. Immutable; lines and financial
  /// details can no longer be edited.
  issued,
}
