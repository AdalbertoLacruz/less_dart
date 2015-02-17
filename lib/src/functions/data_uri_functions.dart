// source: lib/less/functions/data-uri.js 2.2.0

part of functions.less;

//TODO upgrade to 2.2.0 from 1.7.5+
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
    Environment environment = new Environment();
    Logger console = new Logger();

    String mimetype = mimetypeNode.value;
    String filePath = filePathNode != null ? filePathNode.value : mimetype;
    bool useBase64 = false;

    int fragmentStart = filePath.indexOf('#');
    String fragment = '';
    if (fragmentStart != -1) {
      fragment = filePath.substring(fragmentStart);
      filePath = filePath.substring(0, fragmentStart);
    }

    if (this.context.isPathRelative(filePath)) {
      if (this.currentFileInfo.relativeUrls) {
        filePath = environment.pathJoin(this.currentFileInfo.currentDirectory, filePath);
      } else {
        filePath = environment.pathJoin(this.currentFileInfo.entryPath, filePath);
      }
    }

    // detect the mimetype if not given
    if (filePathNode == null) {
      mimetype = environment.mimeLookup(filePath);

      // use base 64 unless it's an ASCII or UTF-8 format
      String charset = environment.charsetLookup(mimetype);
      useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
      if (useBase64)  mimetype += ';base64';
    } else {
      useBase64 = new RegExp(r';base64$').hasMatch(mimetype);
    }

    List<int> buf = new File(filePath).readAsBytesSync();

    // IE8 cannot handle a data-uri larger than 32KB. If this is exceeded
    // and the --ieCompat flag is enabled, return a normal url() instead.

    int DATA_URI_MAX_KB = 32;
    int fileSizeInKB = buf.length ~/ 1024;
    if (fileSizeInKB >= DATA_URI_MAX_KB) {
      if (this.context.ieCompat) {
        if (!this.context.silent) {
          console.warn('Skipped data-uri embedding of ${filePath} because its size (${fileSizeInKB}KB) exceeds IE8-safe ${DATA_URI_MAX_KB}KB!');
        }
        //TODO replace 0 by this.index
        return new URL(getValueOrDefault(filePathNode, mimetypeNode), 0, this.currentFileInfo).eval(this.context);
      }
    }
    String sbuf = useBase64 ? Base64String.encode(buf) : Uri.encodeComponent(new String.fromCharCodes(buf));

    String uri = '"data:${mimetype},${sbuf}${fragment}"';
    return new URL(new Anonymous(uri));

//1.7.5+
//    "data-uri", function(mimetypeNode, filePathNode) {
//
//        if (!less.environment.supportsDataURI(this.env)) {
//            return new tree.URL(filePathNode || mimetypeNode, this.currentFileInfo).eval(this.env);
//        }
//
//        var mimetype = mimetypeNode.value;
//        var filePath = (filePathNode && filePathNode.value);
//
//        var useBase64 = false;
//
//        if (arguments.length < 2) {
//            filePath = mimetype;
//        }
//
//        var fragmentStart = filePath.indexOf('#');
//        var fragment = '';
//        if (fragmentStart!==-1) {
//            fragment = filePath.slice(fragmentStart);
//            filePath = filePath.slice(0, fragmentStart);
//        }
//
//        if (this.env.isPathRelative(filePath)) {
//            if (this.currentFileInfo.relativeUrls) {
//                filePath = less.environment.join(this.currentFileInfo.currentDirectory, filePath);
//            } else {
//                filePath = less.environment.join(this.currentFileInfo.entryPath, filePath);
//            }
//        }
//
//        // detect the mimetype if not given
//        if (arguments.length < 2) {
//
//            mimetype = less.environment.mimeLookup(this.env, filePath);
//
//            // use base 64 unless it's an ASCII or UTF-8 format
//            var charset = less.environment.charsetLookup(this.env, mimetype);
//            useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
//            if (useBase64) { mimetype += ';base64'; }
//        }
//        else {
//            useBase64 = /;base64$/.test(mimetype);
//        }
//
//        var buf = less.environment.readFileSync(filePath);
//
//        // IE8 cannot handle a data-uri larger than 32KB. If this is exceeded
//        // and the --ieCompat flag is enabled, return a normal url() instead.
//        var DATA_URI_MAX_KB = 32,
//            fileSizeInKB = parseInt((buf.length / 1024), 10);
//        if (fileSizeInKB >= DATA_URI_MAX_KB) {
//
//            if (this.env.ieCompat !== false) {
//                if (!this.env.silent) {
//                    console.warn("Skipped data-uri embedding of %s because its size (%dKB) exceeds IE8-safe %dKB!", filePath, fileSizeInKB, DATA_URI_MAX_KB);
//                }
//
//                return new tree.URL(filePathNode || mimetypeNode, this.currentFileInfo).eval(this.env);
//            }
//        }
//
//        buf = useBase64 ? buf.toString('base64')
//            : encodeURIComponent(buf);
//
//        var uri = "\"data:" + mimetype + ',' + buf + fragment + "\"";
//        return new(tree.URL)(new(tree.Anonymous)(uri));
//    };

// 2.2.0
// var   fallback = function(functionThis, node) {
//         return new URL(node, functionThis.index, functionThis.currentFileInfo).eval(functionThis.context);
//     },
//     logger = require('../logger');
//
// functionRegistry.add("data-uri", function(mimetypeNode, filePathNode) {
//
//     if (!filePathNode) {
//         filePathNode = mimetypeNode;
//         mimetypeNode = null;
//     }
//
//     var mimetype = mimetypeNode && mimetypeNode.value;
//     var filePath = filePathNode.value;
//     var currentDirectory = filePathNode.currentFileInfo.relativeUrls ?
//         filePathNode.currentFileInfo.currentDirectory : filePathNode.currentFileInfo.entryPath;
//
//     var fragmentStart = filePath.indexOf('#');
//     var fragment = '';
//     if (fragmentStart!==-1) {
//         fragment = filePath.slice(fragmentStart);
//         filePath = filePath.slice(0, fragmentStart);
//     }
//
//     var fileManager = environment.getFileManager(filePath, currentDirectory, this.context, environment, true);
//
//     if (!fileManager) {
//         return fallback(this, filePathNode);
//     }
//
//     var useBase64 = false;
//
//     // detect the mimetype if not given
//     if (!mimetypeNode) {
//
//         mimetype = environment.mimeLookup(filePath);
//
//   if (mimetype === "image/svg+xml") {
//             useBase64 = false;
//         } else {
//             // use base 64 unless it's an ASCII or UTF-8 format
//             var charset = environment.charsetLookup(mimetype);
//             useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
//         }
//         if (useBase64) { mimetype += ';base64'; }
//     }
//     else {
//         useBase64 = /;base64$/.test(mimetype);
//     }
//
//     var fileSync = fileManager.loadFileSync(filePath, currentDirectory, this.context, environment);
//     if (!fileSync.contents) {
//         logger.warn("Skipped data-uri embedding because file not found");
//         return fallback(this, filePathNode || mimetypeNode);
//     }
//     var buf = fileSync.contents;
// if (useBase64 && !environment.encodeBase64) {
//   return fallback(this, filePathNode);
// }
//
//     buf = useBase64 ? environment.encodeBase64(buf) : encodeURIComponent(buf);
//
//     var uri = "data:" + mimetype + ',' + buf + fragment;
//
// // IE8 cannot handle a data-uri larger than 32,768 characters. If this is exceeded
// // and the --ieCompat flag is enabled, return a normal url() instead.
// var DATA_URI_MAX = 32768;
// if (uri.length >= DATA_URI_MAX) {
//
//   if (this.context.ieCompat !== false) {
//     logger.warn("Skipped data-uri embedding of " + filePath + " because its size (" + uri.length + " characters) exceeds IE8-safe " + DATA_URI_MAX + " characters!");
//
//     return fallback(this, filePathNode || mimetypeNode);
//   }
// }
//
//     return new URL(new Quoted('"' + uri + '"', uri, false, this.index, this.currentFileInfo), this.index, this.currentFileInfo);
// });
  }
}
