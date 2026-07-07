/// Barcode type helpers bridging two different representations:
///
///  1. **Cipherlab scanner strings** – the human-readable names sent by the
///     device via the EventChannel, e.g. "QR Code", "Code 128", "EAN-13".
///     Source: Cipherlab Android Programming Guide v1.12, pages 95-96.
///
///  2. **Backend API ints** – the integer values of the backend `CodeType`
///     enum that come back from the API when fetching stored item codes
///     (serialised as strings "0"–"9" in JSON).
class BarcodeType {
  // ---------------------------------------------------------------------------
  // Cipherlab string → backend CodeType int
  // ---------------------------------------------------------------------------

  static const _cipherlabToApi = <String, int>{
    'QR Code': 0,
    'Micro QR Code': 0,
    'EAN13': 1,
    'EAN13 with Addon 2': 1,
    'EAN13 with Addon 5': 1,
    'Bookland (EAN)': 1,
    'EAN-13': 1, // camera scanner alias
    'EAN8': 2,
    'EAN8 with Addon 2': 2,
    'EAN8 with Addon 5': 2,
    'EAN-8': 2, // camera scanner alias
    'UPC A': 3,
    'UPC A with Addon 2': 3,
    'UPC A with Addon 5': 3,
    'UPC-A': 3, // camera scanner alias
    'Code 128': 4,
    'GS1-128 (EAN 128)': 4,
    'ISBT 128': 10,
    'ISBT 128 Concatenation': 10,
    'Code 39': 5,
    'Trioptic (Code 39)': 5,
    'Data Matrix': 6,
    'PDF417': 7,
    'MicroPDF417': 7,
    'Aztec': 8,
    'Interleaved 2 of 5': 9,
    'Interleaved 25': 9, // camera scanner alias
  };

  // ---------------------------------------------------------------------------
  // Cipherlab strings eligible for Open Food Facts lookup
  // (EAN-13/8, UPC-A, Code128, Code39 family)
  // ---------------------------------------------------------------------------

  static const _offTypes = <String>{
    'EAN13',
    'EAN8',
    'UPC A',
    'Code 128',
    'GS1-128 (EAN 128)',
    'Code 39',
  };

  // ---------------------------------------------------------------------------
  // Backend API int string → display name
  // Used by ItemDetailScreen to label codes stored in the database.
  // ---------------------------------------------------------------------------

  static const _apiToName = <String, String>{
    '0': 'QR Code',
    '1': 'EAN-13',
    '2': 'EAN-8',
    '3': 'UPC-A',
    '4': 'Code 128',
    '5': 'Code 39',
    '6': 'Data Matrix',
    '7': 'PDF417',
    '8': 'Aztec',
    '9': 'ITF-14',
    '10': 'ISBT 128',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Converts a Cipherlab codeType string (e.g. "Code 128") to the integer
  /// value expected by the backend `CodeType` enum. Returns null if the
  /// symbology has no direct backend equivalent.
  static int? fromCipherlab(String? raw) {
    if (raw == null) return null;
    return _cipherlabToApi[raw];
  }

  /// Human-readable display name for a code type.
  ///
  /// Accepts **both**:
  /// - Cipherlab scanner strings ("Code 128") – returned as-is.
  /// - Backend API int strings ("4") – looked up in [_apiToName].
  static String displayName(String? raw) {
    if (raw == null) return 'Unknown';
    if (_cipherlabToApi.containsKey(raw)) return raw;
    return _apiToName[raw] ?? raw;
  }

  /// Returns true when the barcode type is likely to have product data on
  /// Open Food Facts. Accepts Cipherlab scanner strings only.
  static bool supportsOpenFoodFacts(String? raw) {
    if (raw == null) return false;
    return _offTypes.contains(raw);
  }
}
