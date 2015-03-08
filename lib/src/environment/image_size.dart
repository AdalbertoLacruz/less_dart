part of environment.less;

// https://github.com/netroy/image-size 20150306

///
/// calculate the size (width * hight) from a file image
///
class ImageSize {
  List<int> codeUnits;
  String contents;
  String ext;
  String filePath;

  // bmp
  List<int> bmpSignature = [66, 77]; // 'BM'

  // gif
  List<int> gif87Signature = [71, 73, 70, 56, 55, 97]; // 'GIF87a'
  List<int> gif89Signature = [71, 73, 70, 56, 57, 97]; // 'GIF89a'

  // jpg
  Map<String, String> validJFIFMarkers = {
    'ffdb': '0001010101', // Samsung D807 JPEG
    'ffe0': '4a46494600', // Standard JPEG
    'ffe1': '4578696600', // Camera JPEG, with EXIF data
    'ffe2': '4943435f50', // Canon EOS-1D JPEG
    //'ffe3': '',           // Samsung D500 JPEG
    'ffe8': '5350494646', // SPIFF JPEG
    'ffec': '4475636b79', // Photoshop JPEG
    'ffed': '50686f746f', // Adobe JPEG, Photoshop CMYK buffer
    'ffee': '41646f6265'  // Adobe JPEG, Unrecognised (Lightroom??)
  };

  // png
  List<int> pngSignature = [80, 78, 71, 13, 10, 26, 10]; // 'PNG\r\n\x1a\n'
  List<int> ihdrSignature = [73, 72, 68, 82]; // 'IHDR'

  // psd
  List<int> psdSignature = [56, 66, 80, 83]; // '8BPS'

  //svg
  RegExp svgReg = new RegExp(r'<svg[^>]+[^>]*>');
  RegExp svgRootReg = new RegExp(r'<svg [^>]+>');
  RegExp svgWidthReg = new RegExp(r'(^|\s)width\s*=\s*"(.+?)(px)?"', caseSensitive: false);
  RegExp svgHeightReg = new RegExp(r'(^|\s)height\s*=\s*"(.+?)(px)?"', caseSensitive: false);
  RegExp svgViewboxReg = new RegExp(r'(^|\s)viewbox\s*=\s*"(.+?)"', caseSensitive: false);

  /// Read the file and returns the width & heigth dimensions
  ImageDimension sizeOf(String filePath) {
    ImageDimension result;
    ext = pathLib.extension(filePath).toLowerCase();
    this.filePath = filePath;

    switch (ext) {
      case '.bmp':
        loadCodeUnits();
        result = calculateBmp();
        break;
      case '.gif':
        loadCodeUnits();
        result = calculateGif();
        break;
      case '.jpg':
        loadCodeUnits();
        result = calculatejpg();
        break;
      case '.png':
        loadCodeUnits();
        result = calculatePng();
        break;
      case '.psd':
        loadCodeUnits();
        result = calculatePsd();
        break;
      case '.svg':
        loadContents();
        result = calculateSvg();
        break;
      case '.webp':
        loadCodeUnits();
        result = calculateWebp();
    }
    codeUnits = null;
    contents = null;

    return result;
  }


  ///
  /// Reads the file as bytes (List<int>)
  ///
  loadCodeUnits() {
    codeUnits = new File(filePath).readAsBytesSync();
  }

  ///
  /// Reads the file as String
  loadContents() {
    contents = new File(filePath).readAsStringSync();
  }

  ///
  /// True if list a == list b
  ///
  bool compare(List<int> a, List<int> b) {
    if(a.length != b.length) return false;

    bool result = true;
    for (int i = 0; i < a.length; i++) {
      result = result && (a[i] == b[i]);
    }
    return result;
  }

  ///
  /// Return the [list] items converted to hexadecimal string
  ///
  /// Example:
  /// [255, 254] => 'ffe0'
  ///
  String listToHex(List<int> list) {
    return list.fold('', (hex, x) => hex + x.toRadixString(16).padLeft(2, '0'));
  }

  ///
  /// Reads an signed 16 bit integer from [buffer] starting in the [offset] position
  ///
  readInt16LE(int offset, List<int> buffer) {
    String hex = listToHex(buffer.sublist(offset, offset + 2).reversed.toList());
    return int.parse(hex, radix: 16).toSigned(16);
  }

  ///
  /// Reads an unsigned 16 bit integer from the buffer at the specified [offset]
  /// with specified endian format.
  ///
  int readUInt16BE(int offset) {
    int result = codeUnits[offset];
    result = result * 256 + codeUnits[offset + 1];
    return result;
  }

  ///
  /// Reads an unsigned 16 bit integer from the buffer at the specified [offset]
  /// with specified endian format.
  ///
  int readUInt16LE(int offset) {
    int result = codeUnits[offset + 1];
    result = result * 256 + codeUnits[offset];
    return result;
  }

  ///
  /// Reads an unsigned 32 bit integer from the buffer at the specified [offset]
  /// with specified endian format.
  ///
  int readUInt32BE(int offset) {
    int result = codeUnits[offset];
    result = result * 256 + codeUnits[offset + 1];
    result = result * 256 + codeUnits[offset + 2];
    result = result * 256 + codeUnits[offset + 3];
    return result;
  }

  ///
  /// Reads an unsigned 32 bit integer from the buffer at the specified [offset]
  /// with specified endian format.
  ///
  int readUInt32LE(int offset) {
    int result = codeUnits[offset + 3];
    result = result * 256 + codeUnits[offset + 2];
    result = result * 256 + codeUnits[offset + 1];
    result = result * 256 + codeUnits[offset];
    return result;
  }

  // --------------------------- bmp ---------------
  /// check is bmp file
  bool isBmp() {
    return compare(bmpSignature, codeUnits.sublist(0, 2));
  }

  /// Calculate size for bmp file
  ImageDimension calculateBmp() {
    if (!isBmp()) return null;
    return new ImageDimension(width: readUInt32LE(18), height: readUInt32LE(22));
  }

  // --------------------------- gif ---------------

  /// check is gif file
  bool isGif() {
    return compare(gif87Signature, codeUnits.sublist(0, 6))
        || compare(gif89Signature, codeUnits.sublist(0, 6));
  }

  /// Calculate size for gif file
  ImageDimension calculateGif() {
    if (!isGif()) return null;
    return new ImageDimension(width: readUInt16LE(6), height: readUInt16LE(8));
  }

  // --------------------------- jpg ---------------

  /// check is jpg file
  bool isJpg() {
    List<int> SOIMarker = codeUnits.sublist(0, 2);
    List<int> JFIFMarker = codeUnits.sublist(2, 4);

    if (!compare(SOIMarker, [255, 216])) return false; // ffd8

    String jfif = listToHex(JFIFMarker);
    if (!validJFIFMarkers.containsKey(jfif)) return false;
    String expected = validJFIFMarkers[jfif];
    String got = listToHex(codeUnits.sublist(6, 11));

    return (got == expected) || (jfif == 'ffdb');
  }

  /// Assure jpg buffer structure is right
  bool validateJpgBuffer(int i) {
    // index should be within buffer limits
    if (i > codeUnits.length) return false;
    // Every JPEG block must begin with a 0xFF
    if (codeUnits[i] != 255) return false;
    return true;
  }

  /// jpg file size
  ImageDimension extractJpgSize(int i) {
    return new ImageDimension(width: readUInt16BE(i + 2), height: readUInt16BE(i));
  }

  /// Calculate size for jpg file
  ImageDimension calculatejpg() {
    int i;
    int next;

    if (!isJpg()) return null;

    // Skip 5 chars, they are for signature
    codeUnits = codeUnits.sublist(4);

    while (codeUnits.isNotEmpty) {
      // read length of the next block
      i = readUInt16BE(0);

      // ensure correct format
      if (!validateJpgBuffer(i)) return null;

      // 0xFFC0 is baseline(SOF)
      // 0xFFC2 is progressive(SOF2)
      next = codeUnits[i + 1];
      if (next == 192 || next == 194) return extractJpgSize(i + 5);

      // move to the next block
      codeUnits = codeUnits.sublist(i + 2);
    }
    return null;
  }

  // --------------------------- png ---------------

  /// check is png file
  bool isPng() {
    bool result = compare(pngSignature, codeUnits.sublist(1, 8));
    result = result && compare(ihdrSignature, codeUnits.sublist(12, 16));
    return result;
  }

  /// Calculate size for png file
  ImageDimension calculatePng() {
    if (!isPng()) return null;
    return new ImageDimension(width: readUInt32BE(16), height: readUInt32BE(20));
  }

  // --------------------------- psd ---------------

  /// check is psd file
  bool isPsd() {
    return compare(psdSignature, codeUnits.sublist(0, 4));
  }

  /// Calculate size for psd file
  ImageDimension calculatePsd() {
    if (!isPsd()) return null;
    return new ImageDimension(width: readUInt32BE(18), height: readUInt32BE(14));
  }

  // --------------------------- svg ---------------

  /// check is svg file
  bool isSvg() {
    return svgReg.hasMatch(contents);
  }

  double getSvgRatio(Match viewboxMatch) {
    double ratio = 1.0;
    if (viewboxMatch != null && viewboxMatch[2] != null) {
      List<String> dim = viewboxMatch[2].split(' ');
      if (dim.length == 4) {
        List<int> dimi = dim.map((i)=> int.parse(i)).toList();
        ratio = (dimi[2] - dimi[0]) / (dimi[3] - dimi[1]);
      }
    }
    return ratio;
  }

  /// Calculate size for svg file
  ImageDimension calculateSvg() {
    int width;
    int height;
    double ratio;

    if (!isSvg()) return null;

    contents = contents.replaceAll(new RegExp(r'[\r\n\s]+'), ' ');
    Match section = svgRootReg.firstMatch(contents);
    String root = (section != null) ? section[0] : null;
    if (root != null) {
      Match widthMatch = svgWidthReg.firstMatch(root);
      Match heightMatch = svgHeightReg.firstMatch(root);
      Match viewboxMatch = svgViewboxReg.firstMatch(root);

      width = (widthMatch != null) ? int.parse(widthMatch[2]) : null;
      height = (heightMatch != null) ? int.parse(heightMatch[2]) : null;
      ratio = getSvgRatio(viewboxMatch);
    }

    if (width != null && height != null) {
      return new ImageDimension(width: width, height: height);
    } else {
      if (width != null) {
        return new ImageDimension(width: width, height: (width/ ratio).floor());
      } else if (height != null) {
        return new ImageDimension(width: (height * ratio).floor(), height: height);
      } else {
        return null;
      }
    }
  }

  // --------------------------- svg ---------------

  /// check is webp file
  bool isWebp() {
    bool riffHeader = compare([82, 73, 70, 70], codeUnits.sublist(0, 4)); // 'RIFF'
    bool webpHeader = compare([87, 69, 66, 80], codeUnits.sublist(8, 12)); // 'WEBP'
    bool vp8Header = compare([86, 80, 56], codeUnits.sublist(12, 15)); // 'VP8'
    return (riffHeader && webpHeader && vp8Header);
  }

  ///
  ImageDimension calculateWebpLossy(List<int> buffer) {
    // `& 0x3fff` returns the last 14 bits
    int width = readInt16LE(6, buffer) & 0x3fff;
    int height = readInt16LE(8, buffer) & 0x3fff;
    return new ImageDimension(width: width, height: height);
  }

  ///
  ImageDimension calculateWebpLossless(List<int> buffer) {
    int width = 1 + (((buffer[2] & 0x3F) << 8) | buffer[1]);
    int height = 1 + (((buffer[4] & 0xF) << 10) | (buffer[3] << 2) |
                      ((buffer[2] & 0xC0) >> 6));
    return new ImageDimension(width: width, height: height);
  }


  /// calculate size of webp file
  ImageDimension calculateWebp() {
    if (!isWebp()) return null;

    List<int> chunkHeader = codeUnits.sublist(12, 16);
    List<int> buffer = codeUnits.sublist(20, 30);

    // Lossless webp stream signature
    if (compare([86, 80, 56, 32], chunkHeader) && buffer[0] != 47) {  // 'VP8 ' 0x2f
      return calculateWebpLossy(buffer);
    }

    //Lossy webp stream signature
    String signature = listToHex(buffer.sublist(3, 6));
    if (compare([86, 80, 56, 76], chunkHeader) && signature != '9d012a') { // 'VP8L'
      return calculateWebpLossless(buffer);
    }

    return null;
  }
}

// ****************************
class ImageDimension {
  int width;  //px
  int height; //px
  ImageDimension({this.width, this.height});
}