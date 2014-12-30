## Less integration for pub

[Less](http://lesscss.org/)-transformer for [pub-serve](http://pub.dartlang.org/doc/pub-serve.html),  
[pub-build](http://pub.dartlang.org/doc/pub-build.html) and [pub-run](https://www.dartlang.org/tools/pub/cmd/pub-run.html)

This is a traslation from less 1.7.5 Javascript (over nodejs) to Dart. Is a pure Dart implementation.

## pub-run usage

CMD> pub run lessc [args] file.less file.css

A working example:
CMD> pub run lessc test/less/charsets.less

And a error example:
CMD> pub run lessc --no-color test/less/errors/import-subfolder1.less


## pub-build and pub-serve usage

Simply add the following lines to your `pubspec.yaml`:

    dependencies:
      less_dart: any
    transformers:
      - less_dart:
      		entry_point: web/builder.less

After adding the transformer your entry_point `.less` file will be automatically transformed to
corresponding `.css` file.

## Configuration

You can also pass options to Lessc if necessary:

    transformers:
      - less_dart:
          entry_points: 
          	- path/to/builder.less
          	- or/other.less
          output: /path/to/builded.css
          include_path: /path/to/directory/for/less/includes
          cleancss: true or false
          compress: true or false
          build_mode: less, dart or mixed
          other_flags:
            - to include in the lessc command line
          
- entry_point - Is the ONLY option required. Normally is a builder file with "@import 'filexx.less'; ..." directives.
- entry_points - Alternative to entry_point. Let process several .less input files.
- output - Only works with one entry_point file. Is the .css file generated. 
		If not supplied (or several entry_points) then input .less with .css extension changed is used.
- include_path - see [Less Documentation include_path](http://lesscss.org/usage/#command-line-usage-include-paths).
- cleancss - see [Less Documentation clean-css](http://lesscss.org/usage/#command-line-usage-clean-css).
- compress - see [Less Documentation compress](http://lesscss.org/usage/#command-line-usage-compress).
- build_mode -
	- less - command 'CMD> lessc --flags input.less > output.css' is used.
	- dart - command 'CMD> lessc --flags -' with stdin and stdout piped in the dart transformer process. See build folder.
	- mixed - command 'CMD> lessc --flags input.less' with stdout managed by the dart transformer process. See build folder.
- other_flags - Let add other flags such as (-line-numbers=comments, ...) in the lessc command line.


## How to use in other programs

- import 'package:less_dart/less.dart';
- create the Less class: Less less = new Less();
- call transform future.

See a example in: test/simply_test.dart

## Known issues

- Sources from lessc 1.7.5.
- Pass the standard tests in windows (possibly fail with paths in linux).
- Javascript and Dart have different way to treat null, true, ... Many bug must be eliminated yet.
- cleanCSS not implemented yet.
- source-map not implemented yet.
- error color output. Implemented, but not tested in linux. In windows cmd don't work.
- Added option --banner=bannerfile.txt. Could change in next versions according to official version.

- Javascript evaluation not supported. If this is a problem use [less_node](https://pub.dartlang.org/packages/less_node)


## [License](LICENSE)

Copyright (c) 2009-2014 [Alexis Sellier](http://cloudhead.io/) & The Core Less Team.

Copyright (c) 2014 [Adalberto Lacruz](Adalberto.Lacruz@gmail.com) for dart translation.

Licensed under the [Apache License](LICENSE).
