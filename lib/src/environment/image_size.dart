part of environment.less;

// https://github.com/netroy/image-size 20150306

///
/// Calculate the size (width * hight) from a file image
///
class ImageSize {
  ///
  String ext;
  ///
  String filePath;

  ///
  /// Reads the file as bytes (List<int>)
  ///
  List<int> loadCodeUnits() => new File(filePath).readAsBytesSync();

  ///
  /// Reads the file as String
  ///
  String loadContents() => new File(filePath).readAsStringSync();

  ///
  /// Read the file and returns the width & heigth dimensions
  ///
  ImageDimension sizeOf(String filePath) {
    ext = pathLib.extension(filePath).toLowerCase();
    this.filePath = filePath;

    switch (ext) {
      case '.bmp':
        return new BmpImage(loadCodeUnits()).calculate();
      case '.gif':
        return new GifImage(loadCodeUnits()).calculate();
      case '.jpg':
        return new JpgImage(loadCodeUnits()).calculate();
      case '.png':
        return new PngImage(loadCodeUnits()).calculate();
      case '.psd':
        return new PsdImage(loadCodeUnits()).calculate();
      case '.svg':
        return new SvgImage(loadContents()).calculate();
      case '.webp':
        return new WebpImage(loadCodeUnits()).calculate();
    }

    return null;
  }
}

//------------------------------------------------

///
class ImageDimension {
  ///
  int width;  //px
  ///
  int height; //px

  ///
  ImageDimension({this.width, this.height});
}

//------------------------------------------------ .bmp

///
class BmpImage {
  ///
  List<int> codeUnits;
  ///
  List<int> bmpSignature = <int>[66, 77]; // 'BM'

  ///
  BmpImage(this.codeUnits);

  /// check is bmp file
  bool isBmp() => MoreList.compare(bmpSignature, codeUnits.sublist(0, 2));

  /// Calculate size for bmp file
  ImageDimension calculate() {
    if (!isBmp())
        return null;
    return new ImageDimension(
        width:  MoreList.readUInt32LE(codeUnits, 18),
        height: MoreList.readUInt32LE(codeUnits, 22));
  }
}

//------------------------------------------------ .gif

///
class GifImage {
  ///
  List<int> codeUnits;
  ///
  List<int> gif87Signature = <int>[71, 73, 70, 56, 55, 97]; // 'GIF87a'
  ///
  List<int> gif89Signature = <int>[71, 73, 70, 56, 57, 97]; // 'GIF89a'

  ///
  GifImage(this.codeUnits);

  /// check is gif file
  bool isGif() =>
      MoreList.compare(gif87Signature, codeUnits.sublist(0, 6)) ||
      MoreList.compare(gif89Signature, codeUnits.sublist(0, 6));

  /// Calculate size for gif file
  ImageDimension calculate() {
    if (!isGif())
        return null;
    return new ImageDimension(
        width:  MoreList.readUInt16LE(codeUnits, 6),
        height: MoreList.readUInt16LE(codeUnits, 8));
  }
}

//------------------------------------------------ .jpg

///
class JpgImage {
  ///
  List<int> codeUnits;

  ///
  Map<String, String> validJFIFMarkers = <String, String>{
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

  ///
  JpgImage(this.codeUnits);

  ///
  /// check if is jpg file
  ///
  bool isJpg() {
    final List<int> soiMarker = codeUnits.sublist(0, 2);
    final List<int> jfifMarker = codeUnits.sublist(2, 4);

    if (!MoreList.compare(soiMarker, <int>[255, 216]))
        return false; // ffd8

    final String jfif = MoreList.foldHex(jfifMarker);
    if (!validJFIFMarkers.containsKey(jfif))
        return false;

    final String expected = validJFIFMarkers[jfif];
    final String got = MoreList.foldHex(codeUnits.sublist(6, 11));
    return (got == expected) || (jfif == 'ffdb');
  }

  ///
  /// Assure jpg buffer structure is right
  ///
  bool validateJpgBuffer(int i) {
    // index should be within buffer limits
    if (i > codeUnits.length)
        return false;
    // Every JPEG block must begin with a 0xFF
    if (codeUnits[i] != 255)
        return false;
    return true;
  }

  ///
  /// jpg file size
  ///
  ImageDimension extractJpgSize(int i) => new ImageDimension(
      width:  MoreList.readUInt16BE(codeUnits, i + 2),
      height: MoreList.readUInt16BE(codeUnits, i));

  ///
  /// Calculate size for jpg file
  ///
  ImageDimension calculate() {
    int i;
    int next;

    if (!isJpg())
        return null;

    // Skip 5 chars, they are for signature
    codeUnits = codeUnits.sublist(4);

    while (codeUnits.isNotEmpty) {
      // read length of the next block
      i = MoreList.readUInt16BE(codeUnits, 0);

      // ensure correct format
      if (!validateJpgBuffer(i))
          return null;

      // 0xFFC0 is baseline(SOF)
      // 0xFFC2 is progressive(SOF2)
      next = codeUnits[i + 1];
      if (next == 192 || next == 194)
          return extractJpgSize(i + 5);

      // move to the next block
      codeUnits = codeUnits.sublist(i + 2);
    }
    return null;
  }
}

//------------------------------------------------ .png

///
class PngImage {
  ///
  List<int> codeUnits;
  ///
  List<int> pngSignature = <int>[80, 78, 71, 13, 10, 26, 10]; // 'PNG\r\n\x1a\n'
  ///
  List<int> ihdrSignature = <int>[73, 72, 68, 82]; // 'IHDR'

  ///
  PngImage(this.codeUnits);

  ///
  /// check if is png file
  ///
  bool isPng() =>
      MoreList.compare(pngSignature, codeUnits.sublist(1, 8)) &&
      MoreList.compare(ihdrSignature, codeUnits.sublist(12, 16));

  ///
  /// Calculate size for png file
  ///
  ImageDimension calculate() {
    if (!isPng())
        return null;
    return new ImageDimension(
        width:  MoreList.readUInt32BE(codeUnits, 16),
        height: MoreList.readUInt32BE(codeUnits, 20));
  }
}

//------------------------------------------------ .psd

///
class PsdImage {
  ///
  List<int> codeUnits;
  ///
  List<int> psdSignature = <int>[56, 66, 80, 83]; // '8BPS'
  ///
  PsdImage(this.codeUnits);

  ///
  /// check if is psd file
  ///
  bool isPsd() => MoreList.compare(psdSignature, codeUnits.sublist(0, 4));

  ///
  /// Calculate size for psd file
  ///
  ImageDimension calculate() {
    if (!isPsd())
        return null;
    return new ImageDimension(
        width:  MoreList.readUInt32BE(codeUnits, 18),
        height: MoreList.readUInt32BE(codeUnits, 14));
  }
}

//------------------------------------------------ .svg

///
class SvgImage {
  ///
  String contents;
  ///
  RegExp svgReg = new RegExp(r'<svg[^>]+[^>]*>');
  ///
  RegExp svgRootReg = new RegExp(r'<svg [^>]+>');
  ///
  RegExp svgWidthReg = new RegExp(r'(^|\s)width\s*=\s*"(.+?)(px)?"', caseSensitive: false);
  ///
  RegExp svgHeightReg = new RegExp(r'(^|\s)height\s*=\s*"(.+?)(px)?"', caseSensitive: false);
  ///
  RegExp svgViewboxReg = new RegExp(r'(^|\s)viewbox\s*=\s*"(.+?)"', caseSensitive: false);

  ///
  SvgImage(this.contents);

  ///
  /// check if is svg file
  ///
  bool isSvg() => svgReg.hasMatch(contents);

  ///
  double getSvgRatio(Match viewboxMatch) {
    double ratio = 1.0;
    if (viewboxMatch != null && viewboxMatch[2] != null) {
      final List<String> dim = viewboxMatch[2].split(' ');
      if (dim.length == 4) {
        final List<int> dimi = dim.map((String s) => int.parse(s)).toList();
        ratio = (dimi[2] - dimi[0]) / (dimi[3] - dimi[1]);
      }
    }
    return ratio;
  }

  ///
  /// Calculate size for svg file
  ///
  ImageDimension calculate() {
    int     height;
    double  ratio;
    int     width;

    if (!isSvg())
        return null;

    contents = contents.replaceAll(new RegExp(r'[\r\n\s]+'), ' ');
    final Match section = svgRootReg.firstMatch(contents);
    final String root = section?.group(0);
    if (root != null) {
      final Match widthMatch = svgWidthReg.firstMatch(root);
      final Match heightMatch = svgHeightReg.firstMatch(root);
      final Match viewboxMatch = svgViewboxReg.firstMatch(root);

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
}

//------------------------------------------------ .webp

///
class WebpImage {
  ///
  List<int> codeUnits;
  ///
  WebpImage(this.codeUnits);

  ///
  /// check is webp file
  ///
  bool isWebp() {
    final bool riffHeader = MoreList.compare(<int>[82, 73, 70, 70], codeUnits.sublist(0, 4)); // 'RIFF'
    final bool webpHeader = MoreList.compare(<int>[87, 69, 66, 80], codeUnits.sublist(8, 12)); // 'WEBP'
    final bool vp8Header = MoreList.compare(<int>[86, 80, 56], codeUnits.sublist(12, 15)); // 'VP8'
    return (riffHeader && webpHeader && vp8Header);
  }

  ///
  ImageDimension calculateWebpLossy(List<int> buffer) {
    // `& 0x3fff` returns the last 14 bits
    final int width = MoreList.readInt16LE(buffer, 6) & 0x3fff;
    final int height = MoreList.readInt16LE(buffer, 8) & 0x3fff;
    return new ImageDimension(width: width, height: height);
  }

  ///
  ImageDimension calculateWebpLossless(List<int> buffer) {
    final int width = 1 + (((buffer[2] & 0x3F) << 8) | buffer[1]);
    final int height = 1 + (((buffer[4] & 0xF) << 10) | (buffer[3] << 2) |
                      ((buffer[2] & 0xC0) >> 6));
    return new ImageDimension(width: width, height: height);
  }

  ///
  /// calculate size of webp file
  ///
  ImageDimension calculate() {
    if (!isWebp())
        return null;

    final List<int> chunkHeader = codeUnits.sublist(12, 16);
    final List<int> buffer = codeUnits.sublist(20, 30);

    // Lossless webp stream signature
    if (MoreList.compare(<int>[86, 80, 56, 32], chunkHeader) && buffer[0] != 47)   // 'VP8 ' 0x2f
        return calculateWebpLossy(buffer);


    //Lossy webp stream signature
    final String signature = MoreList.foldHex(buffer.sublist(3, 6));
    if (MoreList.compare(<int>[86, 80, 56, 76], chunkHeader) && signature != '9d012a')  // 'VP8L'
        return calculateWebpLossless(buffer);

    return null;
  }
}
