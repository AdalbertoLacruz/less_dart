part of environment.less;

///
/// List functions
///
class MoreList {

  ///
  /// Add [element] if not found
  ///
  static void addUnique<T>(List<T> to, T element) {
    if (!to.contains(element)) to.add(element);
  }

  ///
  /// Add all elements of [from] to [to] after transformation with
  /// function: map(element) => other element
  ///
  static List<T> addAllUnique<T>(List<T> to, List<T> from, {Function map}) {
    if (from == null) return to;
    from.forEach((T item){
      if (map != null) item = map(item);
      addUnique(to, item);
    });
    return to;
  }

  ///
  /// True if list a == list b
  ///
  static bool compare<T>(List<T> a, List<T> b) {
    if (a == null || b == null) return false;
    if(a.length != b.length) return false;

    bool result = true;
    for (int i = 0; i < a.length; i++) {
      result = result && (a[i] == b[i]);
    }
    return result;
  }

  //
  // Returns the indexth element.
  // If index < 0 || index >= length => null
  //
  /* static dynamic elementAt(List list, int index) {
    if (list == null) return null;
    if (index < 0) return null;
    if (index >= list.length) return null;
    return list[index];
  }*/

  ///
  /// Return the [list]<int> codeUnits (0-255) converted to hexadecimal string
  ///
  /// Example:
  /// [255, 254] => 'ffe0'
  ///
  static String foldHex(List<int> list) {
    return list.fold('', (String hex, int x) => hex + x.toRadixString(16).padLeft(2, '0'));
  }

  ///
  /// Reads an signed 16 bit integer from the [buffer] starting in the [offset] position
  /// with specified endian format. [buffer] is List<int> (0..255).
  ///
  static int readInt16LE(List<int> buffer, int offset) {
    String hex = MoreList.foldHex(buffer.sublist(offset, offset + 2).reversed.toList());
    return int.parse(hex, radix: 16).toSigned(16);
  }

  ///
  /// Reads an unsigned 16 bit integer from the [buffer] at the specified [offset] position
  /// with specified endian format. [buffer] is List<int> (0..255).
  ///
  static int readUInt16BE(List<int> buffer, int offset) {
    int result = buffer[offset];
    result = result * 256 + buffer[offset + 1];
    return result;
  }

  ///
  /// Reads an unsigned 16 bit integer from the [buffer] at the specified [offset] position
  /// with specified endian format. [buffer] is List<int> (0..255).
  ///
  static int readUInt16LE(List<int> buffer, int offset) {
    int result = buffer[offset + 1];
    result = result * 256 + buffer[offset];
    return result;
  }

  ///
  /// Reads an unsigned 32 bit integer from the [buffer] at the specified [offset] position
  /// with specified endian format. [buffer] is List<int> (0..255).
  ///
  static int readUInt32BE(List<int> buffer, int offset) {
    int result = buffer[offset];
    result = result * 256 + buffer[offset + 1];
    result = result * 256 + buffer[offset + 2];
    result = result * 256 + buffer[offset + 3];
    return result;
  }

  ///
  /// Reads an unsigned 32 bit integer from the buffer at the specified [offset]
  /// with specified endian format.
  ///
  static int readUInt32LE(List<int> buffer, int offset) {
    int result = buffer[offset + 3];
    result = result * 256 + buffer[offset + 2];
    result = result * 256 + buffer[offset + 1];
    result = result * 256 + buffer[offset];
    return result;
  }
}
