##Native Dart Less compiler/transformer to build .css files from .less files

[Less](http://lesscss.org/)-transformer for [pub-serve](http://pub.dartlang.org/doc/pub-serve.html), [pub-build](http://pub.dartlang.org/doc/pub-build.html) and Less-compiler for [pub-run](https://www.dartlang.org/tools/pub/cmd/pub-run.html)

This is a traslation from less 1.7.5 Javascript (over nodejs) to Dart. 
Is a pure Dart implementation for the server/developper side.

## Use as Compiler or Transformer

The package is a less compiler with wrappers for use in command line or as a dart 
transformer. Also, it could be used in other Dart programs.

### pub-run usage

If you get the full distribution (tar.gz file), the bin directory has the lessc.dart 
for use with pub run:

    `CMD> pub run lessc [args] file.less file.css`

A working example: `CMD> pub run lessc test/less/charsets.less`

And a error example: `CMD> pub run lessc --no-color test/less/errors/import-subfolder1.less`

For help: `CMD> pub run lessc --help`

### How to use in other dart programs

You would need import the package, create the Less class and call the transform future. 
There is a example:

      import 'dart:io';
      import 'package:less_dart/less.dart';
      
      main() {
        List<String> args = [];
        Less less = new Less();
      
        args.add('-no-color');
        args.add('--strict-math=on');
        args.add('--strict-units=on');
        args.add('less/charsets.less');
        less.transform(args).then((exitCode){
          stderr.write(less.stderr.toString());
          stdout.writeln('\nstdout:');
          stdout.write(less.stdout.toString());
        });
      }

### Use as a Dart Transformer with pub-build or pub-serve

Simply add the following lines to your `pubspec.yaml`:

    dependencies:
      less_dart: any
    transformers:
      - less_dart:
      		entry_point: web/builder.less

After adding the transformer your entry_point `.less` file will be automatically 
transformed to corresponding `.css` file.

The power of Dart builder is chain transformers, so a less file will be converted 
to a css file and this could be the source for a polymer transformer, by example. 
Considerer to use the less transformer as the first in the chain.


#### Transformer Configuration

You can also pass options to lessc if necessary:

    transformers:
      - less_dart:
          entry_points: 
          	- path/to/builder.less
          	- or/other.less
          output: /path/to/builded.css
          include_path: /path/to/directory/for/less/includes
          cleancss: true or false
          compress: true or false
          build_mode: less, dart or mixed. (dart by default)
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
	- less - command 'CMD> lessc --flags input.less output.css' is used. (output.css is in the same directory as input.less)
	- dart - command 'CMD> lessc --flags -' with stdin and stdout piped in the dart transformer process. See build folder for the css file.
	- mixed - command 'CMD> lessc --flags input.less' with stdout managed by the dart transformer process. See build folder for the css file.
- other_flags - Let add other flags such as (--source-map, ...) in the lessc command line.



## Known issues

- Sources from lessc 1.7.5.
- Pass the standard tests in windows (no tested in linux).
- Javascript and Dart have different way to treat null, true, ... Some bugs must be eliminated yet.
- cleanCSS not implemented yet.
- error color output. Implemented, but not tested in linux. In windows cmd don't support the color commands.
- Added option --banner=bannerfile.txt. Could change in next versions according to official version.

- Javascript evaluation not supported. If this is a problem use [less_node](https://pub.dartlang.org/packages/less_node)


## [License](LICENSE)

Copyright (c) 2009-2015 [Alexis Sellier](http://cloudhead.io/) & The Core Less Team.

Copyright (c) 2014-2015 [Adalberto Lacruz](Adalberto.Lacruz@gmail.com) for dart translation.

Licensed under the [Apache License](LICENSE).
