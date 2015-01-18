library environment.less;

import 'dart:async';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as path;

import '../less_error.dart';

class Environment {
  static Map<int, Environment> cache = {};

  Environment._();

  ///
  /// Returns the environment for this runZoned
  ///
  /// If not runZoned, #id == null. Example:
  /// runZoned((){...
  ///   environment = new Environment();
  /// },
  /// zoneValues: {#id: new Random().nextInt(10000)});
  ///
  factory Environment() {
    int id = Zone.current[#id];
    if (id == null) id = -1;
    if(cache[id] == null) cache[id] = new Environment._();

    return cache[id];
  }

  /// Join and normalize two parts of path
  String pathJoin(String basePath, String laterPath){
    return path.normalize(path.join(basePath, laterPath));
  }

  ///
  /// Lookup the mime-type of a [filename]
  ///
  String mimeLookup(String filename) {
    String type = mime.lookupMimeType(filename);
    if (type == null) {
      String ext = path.extension(filename);
          throw new LessExceptionError(new LessError(
              message: 'Optional dependency "mime" is required for $ext'));
        }
    return type;
  }

  ///
  /// Look up the charset of a [mime] type
  ///
  String charsetLookup(String mime) {
    // assumes all text types are UTF-8
    RegExp re = new RegExp(r'^text\/');

    return (mime != null && re.hasMatch(mime)) ? 'UTF-8' : '';
  }

}