/// Tracks the item currently visible on screen so the global hardware scanner
/// can offer "add this barcode to the current item" when a scan is unknown.
///
/// [ItemDetailScreen] sets [itemId], [itemName], and [onReload] in its
/// initState / _loadItem, and clears them in dispose.
class ActiveItemState {
  static int? itemId;
  static String? itemName;

  /// Called after a barcode is successfully added via the global scanner,
  /// so the detail screen can reload without user intervention.
  static void Function()? onReload;
}
