import 'dart:io';

import 'package:test/test.dart';

import '../lib/src/less_options.dart';
//import '../lib/src/logger.dart';

void main() {
//  SimpleConfiguration config = new SimpleConfiguration();
//  config.throwOnTestFailures = false;
//  config.stopTestOnExpectFailure = false;
//  unittestConfiguration = config;

  lessOptionsTest();
}

/// -
void lessOptionsTest() {
  group('less_options', () {
    LessOptions options;
    bool        result;

    final RegExp regOption =
        new RegExp(r'^--?([a-z][0-9a-z-]*)(?:=(.*))?$', caseSensitive: false);

    Match getArgument(String argument) => regOption.firstMatch(argument);

    setUp(() {
      options = new LessOptions();
    });

    test('-v', () {
      result = options.parse(getArgument('-v'));
      expect(result, false);
    });

    test('-version', () {
      result = options.parse(getArgument('-version'));
      expect(result, false);
    });

    test('-verbose', () {
      result = options.parse(getArgument('-verbose'));
      expect(result, true);
      expect(options.verbose, true);
    });

    test('-s', () {
      result = options.parse(getArgument('-s'));
      expect(result, true);
      expect(options.silent, true);
    });

    test('-silent', () {
      result = options.parse(getArgument('-silent'));
      expect(result, true);
      expect(options.silent, true);
    });

    test('-l', () {
      result = options.parse(getArgument('-l'));
      expect(result, true);
      expect(options.lint, true);
    });

    test('-lint', () {
      result = options.parse(getArgument('-lint'));
      expect(result, true);
      expect(options.lint, true);
    });

    test('-strict-imports', () {
      result = options.parse(getArgument('-strict-imports'));
      expect(result, true);
      expect(options.strictImports, true);
    });

    test('-h', () {
      result = options.parse(getArgument('-h'));
      expect(result, false);
    });

    test('-help', () {
      result = options.parse(getArgument('-help'));
      expect(result, false);
    });

    test('-x', () {
      result = options.parse(getArgument('-x'));
      expect(result, true);
      expect(options.compress, true);
    });

    test('-compress', () {
      result = options.parse(getArgument('-compress'));
      expect(result, true);
      expect(options.compress, true);
    });

    test('-insecure', () {
      result = options.parse(getArgument('-insecure'));
      expect(result, true);
      expect(options.insecure, true);
    });

    test('-M', () {
      result = options.parse(getArgument('-M'));
      expect(result, true);
      expect(options.depends, true);
    });

    test('-depends', () {
      result = options.parse(getArgument('-depends'));
      expect(result, true);
      expect(options.depends, true);
    });

    test('-max-line-len', () {
      result = options.parse(getArgument('-max-line-len=80'));
      expect(result, true);
      expect(options.maxLineLen, equals(80));
    });

    test('-no-color', () {
      result = options.parse(getArgument('-no-color'));
      expect(result, true);
      expect(options.color, false);
    });

    test('-ie-compat', () {
      result = options.parse(getArgument('-ie-compat'));
      expect(result, true);
      expect(options.ieCompat, true);
    });

    test('-no-js', () {
      result = options.parse(getArgument('-no-js'));
      expect(result, false);
    });

    test('-include-path', () {
      final String sep = Platform.isWindows ? ';' : ':';
      result = options.parse(getArgument('-include-path=lib/lessIncludes${sep}lib/otherIncludes'));
      expect(result, true);
      expect(options.paths, contains('lib/otherIncludes'));
    });

    test('-line-numbers', () {
      result = options.parse(getArgument('-line-numbers=comments'));
      expect(result, true);
      expect(options.dumpLineNumbers, equals('comments'));
    });

    test('-source-map', () {
      result = options.parse(getArgument('-source-map'));
      expect(result, true);
      expect(options.sourceMap, true);
    });

    test('-source-map file', () {
      result = options.parse(getArgument('-source-map=file.dat'));
      expect(result, true);
      expect(options.sourceMapOptions.sourceMapFullFilename, equals('file.dat'));
    });

    test('-source-map-rootpath', () {
      result = options.parse(getArgument('-source-map-rootpath=path/to'));
      expect(result, true);
      expect(options.sourceMapOptions.sourceMapRootpath, equals('path/to'));
    });

    test('-source-map-basepath', () {
      result = options.parse(getArgument('-source-map-basepath=path/to'));
      expect(result, true);
      expect(options.sourceMapOptions.sourceMapBasepath, equals('path/to'));
    });

    test('-source-map-map-inline', () {
      result = options.parse(getArgument('-source-map-map-inline'));
      expect(result, true);
      expect(options.sourceMapOptions.sourceMapFileInline, true);
    });

    test('-source-map-less-inline', () {
      result = options.parse(getArgument('-source-map-less-inline'));
      expect(result, true);
      expect(options.sourceMapOptions.outputSourceFiles, true);
    });

    test('-source-map-url', () {
      result = options.parse(getArgument('-source-map-url=http://url/to.this'));
      expect(result, true);
      expect(options.sourceMapOptions.sourceMapURL, equals('http://url/to.this'));
    });

    test('-rp', () {
      result = options.parse(getArgument('-rp=http://url/to.this'));
      expect(result, true);
      expect(options.rootpath, equals('http://url/to.this'));
    });

    test('-rootpath', () {
      result = options.parse(getArgument(r'-rootpath=http://url\to.this'));
      expect(result, true);
      expect(options.rootpath, equals('http://url/to.this'));
    });

    test('-ru', () {
      result = options.parse(getArgument('-ru'));
      expect(result, true);
      expect(options.relativeUrls, true);
    });

    test('-relative-urls', () {
      result = options.parse(getArgument('-relative-urls'));
      expect(result, true);
      expect(options.relativeUrls, true);
    });

    test('-sm on', () {
      result = options.parse(getArgument('-sm=on'));
      expect(result, true);
      expect(options.strictMath, true);
    });

    test('-strict-math off', () {
      result = options.parse(getArgument('-strict-math=off'));
      expect(result, true);
      expect(options.strictMath, false);
    });

    test('-su', () {
      result = options.parse(getArgument('-su=on'));
      expect(result, true);
      expect(options.strictUnits, true);
    });

    test('-strict-units', () {
      result = options.parse(getArgument('-strict-units=off'));
      expect(result, true);
      expect(options.strictUnits, false);
    });

    test('-global-var', () {
      result = options.parse(getArgument('-global-var=var=value'));
      expect(result, true);
      expect(options.globalVariables.length, equals(1));
    });

    test('-modify-var', () {
      result = options.parse(getArgument('-modify-var=var=value'));
      expect(result, true);
      expect(options.modifyVariables.length, equals(1));
    });

    test('-url-args', () {
      result = options.parse(getArgument('-url-args=cb=42'));
      expect(result, true);
      expect(options.urlArgs, equals('cb=42'));
    });

    //check errors

    test('no arguments', () {
      result = options.parse(getArgument(''));
      expect(result, false);
    });

    test('-max-line-len no number', () {
      result = options.parse(getArgument('-max-line-len=bad'));
      expect(result, false);
    });

    test('-include-path no path', () {
      result = options.parse(getArgument('-include-path'));
      expect(result, false);
    });

    test('-line-numbers no argument', () {
      result = options.parse(getArgument('-line-numbers'));
      expect(result, false);
    });

    test('-source-map-rootpath no argument', () {
      result = options.parse(getArgument('-source-map-rootpath'));
      expect(result, false);
    });

    test('-source-map-basepath no argument', () {
      result = options.parse(getArgument('-source-map-basepath'));
      expect(result, false);
    });

    test('-source-map-url no argument', () {
      result = options.parse(getArgument('-source-map-url'));
      expect(result, false);
    });

    test('-rootpath no argument', () {
      result = options.parse(getArgument('-rootpath'));
      expect(result, false);
    });

    test('-strict-math bad', () {
      result = options.parse(getArgument('-strict-math=bad'));
      expect(result, false);
      expect(options.strictMath, false);
    });

    test('-strict-units bad', () {
      result = options.parse(getArgument('-strict-units=bad'));
      expect(result, false);
      expect(options.strictUnits, false);
    });

    test('-global-var no argument', () {
      result = options.parse(getArgument('-global-var'));
      expect(result, false);
    });

    test('-modify-var no argument', () {
      result = options.parse(getArgument('-modify-var'));
      expect(result, false);
    });

    test('-url-args no argument', () {
      result = options.parse(getArgument('-url-args'));
      expect(result, false);
    });
  });
}
