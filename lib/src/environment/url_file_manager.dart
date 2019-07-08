//source: lib/less-node/url-file-manager.js 2.5.0

part of environment.less;

/// URL loader
class UrlFileManager extends AbstractFileManager {
  ///
  RegExp isUrlRe = new RegExp(r'^(?:https?:)?\/\/', caseSensitive: false);

  ///
  UrlFileManager(Environment environment) : super(environment);

  ///
  /// True is can load the file
  ///
  @override
  bool supports (String filename, String currentDirectory, Contexts options, Environment environment) =>
      isUrlRe.hasMatch(filename) || isUrlRe.hasMatch(currentDirectory);

//2.3.1
//UrlFileManager.prototype.supports = function(filename, currentDirectory, options, environment) {
//    return isUrlRe.test( filename ) || isUrlRe.test(currentDirectory);
//};

  /// Load async the url
  //TODO options.strictSSL
  @override
  Future<FileLoaded> loadFile(String filename, String currentDirectory, Contexts options, Environment environment) {
    final StringBuffer dataBuffer = new StringBuffer();
    final HttpClient client = new HttpClient();
    final Completer<FileLoaded> task = new Completer<FileLoaded>();

    final String urlStr = isUrlRe.hasMatch(filename)
        ? filename
        : new Uri.file(currentDirectory).resolve(filename);

    client
        .getUrl(Uri.parse(urlStr))
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) {
          response.cast<List<int>>().transform(utf8.decoder).listen((String contents) {
            dataBuffer.write(contents);
          }, onDone: () {
            if (response.statusCode == 404) {
              final LessError error = new LessError(
                  type: 'File',
                  message: 'resource " $urlStr " was not found\n'
              );
              return task.completeError(error);
            }
            if (dataBuffer.isEmpty) {
              environment.logger.warn( 'Warning: Empty body (HTTP ${response.statusCode}) returned by "$urlStr"');
            }
            final FileLoaded fileLoaded = new FileLoaded(
                filename: urlStr,
                contents: dataBuffer.toString()
            );
            task.complete(fileLoaded);
          });
        }).catchError((dynamic e, StackTrace s) {
          final LessError error = new LessError(
              type: 'File',
              message: 'resource "$urlStr" gave this Error:\n  ${e.message}\n'
          );
          task.completeError(error);
        });

    return task.future;

//2.3.1
//UrlFileManager.prototype.loadFile = function(filename, currentDirectory, options, environment) {
//    return new PromiseConstructor(function(fulfill, reject) {
//        if (request === undefined) {
//            try { request = require('request'); }
//            catch(e) { request = null; }
//        }
//        if (!request) {
//            reject({ type: 'File', message: "optional dependency 'request' required to import over http(s)\n" });
//            return;
//        }
//
//        var urlStr = isUrlRe.test( filename ) ? filename : url.resolve(currentDirectory, filename),
//            urlObj = url.parse(urlStr);
//
//        if (!urlObj.protocol) {
//            urlObj.protocol = "http";
//            urlStr = urlObj.format();
//        }
//
//        request.get({uri: urlStr, strictSSL: !options.insecure }, function (error, res, body) {
//            if (error) {
//                reject({ type: 'File', message: "resource '" + urlStr + "' gave this Error:\n  " + error + "\n" });
//                return;
//            }
//            if (res && res.statusCode === 404) {
//                reject({ type: 'File', message: "resource '" + urlStr + "' was not found\n" });
//                return;
//            }
//            if (!body) {
//                logger.warn('Warning: Empty body (HTTP '+ res.statusCode + ') returned by "' + urlStr + '"');
//            }
//            fulfill({ contents: body, filename: urlStr });
//        });
//    });
//};
  }
}
