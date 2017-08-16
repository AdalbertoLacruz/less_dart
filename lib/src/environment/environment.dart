//source: lib/less/environment.js 2.5.0

library environment.less;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:barback/barback.dart';
import 'package:less_dart/src/environment/package_resolver_provider.dart';
import 'package:mime/mime.dart' as mime;
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as pathLib;

import '../contexts.dart';
import '../less_error.dart';
import '../less_options.dart';
import '../logger.dart';

part 'base64_string.dart';
part 'bi_map.dart';
part 'debug_functions.dart';
part 'file_file_manager.dart';
part 'file_manager.dart';
part 'global_functions.dart';
part 'image_size.dart';
part 'more_list.dart';
part 'more_reg_exp.dart';
part 'url_file_manager.dart';

///
class Environment {
  ///
  static Map<int, Environment>  cache = <int, Environment>{};
  ///
  List<FileManager>             fileManagers;
  ///
  Logger                        logger = new Logger();
  ///
  LessOptions                   options;

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
    final int id = Zone.current[#id] ?? -1;
    cache[id] ??= new Environment._();
    return cache[id];
  }

  Environment._();

  /// Join and normalize two parts of path
  String pathJoin(String basePath, String laterPath) =>
      pathLib.normalize(pathLib.join(basePath, laterPath));

  /// Normalize the path
//  String pathNormalize(String basePath) => pathLib.normalize(basePath);

  ///
  /// Lookup the mime-type of a [filename]
  ///
  String mimeLookup(String filename) {
    final String type = mime.lookupMimeType(filename);

    if (type == null) {
      final String ext = pathLib.extension(filename);
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
    final RegExp re = new RegExp(r'^text\/');

    return (mime != null && re.hasMatch(mime)) ? 'UTF-8' : '';
  }

  ///
  /// Returns the UrlFileManager or FileFileManager to load the [filename]
  ///
  FileManager getFileManager(String filename, String currentDirectory,
        Contexts options, Environment environment,
        {bool isSync = false}) {

    FileManager fileManager;

    if (filename == null)
        logger.warn("getFileManager called with no filename.. Please report this issue. continuing.");

    if (currentDirectory == null)
        logger.warn("getFileManager called with null directory.. Please report this issue. continuing.");

    if (fileManagers == null) {
      fileManagers = <FileManager>[
          //order is important
          new FileFileManager(environment, new PackageResolverProvider()),
          new UrlFileManager(environment)
      ];
      if (options.pluginManager != null)
          fileManagers.addAll(options.pluginManager.getFileManagers());
    }

    for (int i = fileManagers.length - 1; i >= 0; i--) {
      fileManager = fileManagers[i];
      if (isSync && fileManager.supportsSync(filename, currentDirectory, options, environment))
          return fileManager;
      if (!isSync && fileManager.supports(filename, currentDirectory, options, environment))
          return fileManager;
    }
    return null;

//2.3.1
//  environment.prototype.getFileManager = function (filename, currentDirectory, options, environment, isSync) {
//
//      if (!filename) {
//          logger.warn("getFileManager called with no filename.. Please report this issue. continuing.");
//      }
//      if (currentDirectory == null) {
//          logger.warn("getFileManager called with null directory.. Please report this issue. continuing.");
//      }
//
//      var fileManagers = this.fileManagers;
//      if (options.pluginManager) {
//          fileManagers = [].concat(fileManagers).concat(options.pluginManager.getFileManagers());
//      }
//      for(var i = fileManagers.length - 1; i >= 0 ; i--) {
//          var fileManager = fileManagers[i];
//          if (fileManager[isSync ? "supportsSync" : "supports"](filename, currentDirectory, options, environment)) {
//              return fileManager;
//          }
//      }
//      return null;
//  };
  }
}
