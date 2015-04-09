// source: lib/less/functions/data-uri.js 2.5.0

part of functions.less;

class DataUriFunctions extends FunctionBase {
  ///
  /// Inlines a resource and falls back to url() if the ieCompat option is on and
  /// the resource is too large. If the MIME type is not given then uses
  /// the mime package to determine the correct mime type.
  ///
  /// Parameters:
  ///   mimetype: (Optional) A MIME type string.
  ///   url: The URL of the file to inline.
  /// Example: data-uri('../data/image.jpg');
  ///   Output: url('data:image/jpeg;base64,bm90IGFjdHVhbGx5IGEganBlZyBmaWxlCg==');
  /// Example: data-uri('image/svg+xml;charset=UTF-8', 'image.svg');
  ///   Output: url("data:image/svg+xml;charset=UTF-8,%3Csvg%3E%3Ccircle%20r%3D%229%22%2F%3E%3C%2Fsvg%3E");
  ///
  @defineMethod(name: 'data-uri')
  URL dataURI(Node mimetypeNode, [Node filePathNode]) {

    URL fallback() {
      return new URL(getValueOrDefault(filePathNode, mimetypeNode), this.index, this.currentFileInfo).eval(this.context);
    }

    Environment environment = new Environment();
    Logger logger = environment.logger;

    if (filePathNode == null) {
      filePathNode = mimetypeNode;
      mimetypeNode = null;
    }

    String mimetype = mimetypeNode != null ? mimetypeNode.value : null;
    String filePath = filePathNode.value;
    FileInfo currentFileInfo = this.currentFileInfo;
    String currentDirectory = currentFileInfo.relativeUrls
        ? currentFileInfo.currentDirectory
        : currentFileInfo.entryPath;

    int fragmentStart = filePath.indexOf('#');
    String fragment = '';
    if (fragmentStart != -1) {
      fragment = filePath.substring(fragmentStart);
      filePath = filePath.substring(0, fragmentStart);
    }

    FileManager fileManager = environment.getFileManager(filePath,
        currentDirectory, this.context, environment, true);
    if (fileManager == null) return fallback();

    bool useBase64 = false;

    // detect the mimetype if not given
    if (mimetypeNode == null) {
      mimetype = environment.mimeLookup(filePath);

      if (mimetype == 'image/svg+xml') {
        useBase64 = false;
      } else {
        // use base 64 unless it's an ASCII or UTF-8 format
        String charset = environment.charsetLookup(mimetype);
        useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
      }
      if (useBase64)  mimetype += ';base64';
    } else {
      useBase64 = new RegExp(r';base64$').hasMatch(mimetype);
    }

    FileLoaded fileSync = fileManager.loadFileAsBytesSync(filePath,
        currentDirectory, context, environment);
    if (fileSync.codeUnits == null) {
      logger.warn('Skipped data-uri embedding of ${filePath} because file not found');
      return fallback();
    }
    List<int> buf = fileSync.codeUnits;
    String sbuf = useBase64
        ? Base64String.encode(buf)
        : Uri.encodeComponent(new String.fromCharCodes(buf));

    String uri = 'data:${mimetype},${sbuf}${fragment}';

    // IE8 cannot handle a data-uri larger than 32,768 characteres. If this is exceeded
    // and the --ieCompat flag is enabled, return a normal url() instead.

    int DATA_URI_MAX = 32768;
    if (buf.length >= DATA_URI_MAX) {
      if (this.context.ieCompat) {
        logger.warn('Skipped data-uri embedding of ${filePath} because its size (${buf.length} characters) exceeds IE8-safe ${DATA_URI_MAX} characters!');
        return fallback();
      }
    }
    return new URL(new Quoted('"' + uri + '"', uri, false, index, currentFileInfo), index, currentFileInfo);

//2.4.0
//  fallback = function(functionThis, node) {
//              return new URL(node, functionThis.index, functionThis.currentFileInfo).eval(functionThis.context);
//          },
//  functionRegistry.add("data-uri", function(mimetypeNode, filePathNode) {
//
//      if (!filePathNode) {
//          filePathNode = mimetypeNode;
//          mimetypeNode = null;
//      }
//
//      var mimetype = mimetypeNode && mimetypeNode.value;
//      var filePath = filePathNode.value;
//      var currentFileInfo = this.currentFileInfo;
//      var currentDirectory = currentFileInfo.relativeUrls ?
//          currentFileInfo.currentDirectory : currentFileInfo.entryPath;
//
//      var fragmentStart = filePath.indexOf('#');
//      var fragment = '';
//      if (fragmentStart !== -1) {
//          fragment = filePath.slice(fragmentStart);
//          filePath = filePath.slice(0, fragmentStart);
//      }
//
//      var fileManager = environment.getFileManager(filePath, currentDirectory, this.context, environment, true);
//
//      if (!fileManager) {
//          return fallback(this, filePathNode);
//      }
//
//      var useBase64 = false;
//
//      // detect the mimetype if not given
//      if (!mimetypeNode) {
//
//          mimetype = environment.mimeLookup(filePath);
//
//          if (mimetype === "image/svg+xml") {
//              useBase64 = false;
//          } else {
//              // use base 64 unless it's an ASCII or UTF-8 format
//              var charset = environment.charsetLookup(mimetype);
//              useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
//          }
//          if (useBase64) { mimetype += ';base64'; }
//      }
//      else {
//          useBase64 = /;base64$/.test(mimetype);
//      }
//
//      var fileSync = fileManager.loadFileSync(filePath, currentDirectory, this.context, environment);
//      if (!fileSync.contents) {
//          logger.warn("Skipped data-uri embedding of " + filePath + " because file not found");
//          return fallback(this, filePathNode || mimetypeNode);
//      }
//      var buf = fileSync.contents;
//      if (useBase64 && !environment.encodeBase64) {
//          return fallback(this, filePathNode);
//      }
//
//      buf = useBase64 ? environment.encodeBase64(buf) : encodeURIComponent(buf);
//
//      var uri = "data:" + mimetype + ',' + buf + fragment;
//
//      // IE8 cannot handle a data-uri larger than 32,768 characters. If this is exceeded
//      // and the --ieCompat flag is enabled, return a normal url() instead.
//      var DATA_URI_MAX = 32768;
//      if (uri.length >= DATA_URI_MAX) {
//
//          if (this.context.ieCompat !== false) {
//              logger.warn("Skipped data-uri embedding of " + filePath + " because its size (" + uri.length +
//                  " characters) exceeds IE8-safe " + DATA_URI_MAX + " characters!");
//
//              return fallback(this, filePathNode || mimetypeNode);
//          }
//      }
//
//      return new URL(new Quoted('"' + uri + '"', uri, false, this.index, this.currentFileInfo), this.index, this.currentFileInfo);
//  });
  }
}
