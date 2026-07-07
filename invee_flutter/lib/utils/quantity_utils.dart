import '../models/item.dart';

/// Returns true when an item's tracked quantity is definitively zero/empty.
/// - Precise (quantityType == '2'): quantity <= 0
/// - Levels  (quantityType == '1'): level == '0' (None)
/// - None    (quantityType == '0'): unknown stock — never treated as zero
bool isZeroAmount(ItemListEntry item) {
  if (item.quantityType == '2') {
    return (item.quantity ?? 0) <= 0;
  }
  if (item.quantityType == '1') {
    return item.level == '0';
  }
  return false;
}
