/// Client-generated ids for rows created offline (ICASS tasks, chat messages).
/// Microsecond timestamps are unique enough for a single device's local data.
String newLocalId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
