##Native Dart Less compiler/transformer to build .css files from .less files

[Less](http://lesscss.org/)-transformer for [pub-serve](http://pub.dartlang.org/doc/pub-serve.html), [pub-build](http://pub.dartlang.org/doc/pub-build.html) and Less-compiler for [pub-run](https://www.dartlang.org/tools/pub/cmd/pub-run.html)

This is a translation from Less 2.4.0 Javascript (over nodejs) to Dart. 
Is a pure Dart implementation for the server/developer side.

As transformer could work with `.html` files, converting `<less>` tags to `<style>` tags.


## Use as Compiler or Transformer

The package is a Less compiler with wrappers for use in command line or as a dart 
transformer. Also, it could be used in other Dart programs.


### Pub-run usage

If you get the full distribution (tar.gz file), the bin directory has the `lessc.dart` file 
for use with pub run:

    CMD> pub run lessc [args] file.less file.css

A working example: `CMD> pub run lessc test/less/charsets.less`

Example with error output: `CMD> pub run lessc --no-color test/less/errors/import-subfolder1.less`

For help: `CMD> pub run lessc --help`


### How to use in other dart programs

You would need import the package, create the Less class and call the transform future. 
There is an example:

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

Simply add the following lines to your `pubspec.yaml` to work with the default options:

    dependencies:
      less_dart: any
    transformers:
      - less_dart

After adding the transformer all your `.less` files will be automatically 
transformed to corresponding `.css` files. Also the `.html` files will be processed.
This is the standard default, but it could be modified by inclusion or exclusion paths.
The exclusion paths start with '!'. And the '*' is supported in the paths.

The power of Dart builder is chain transformers, so a `.less` file will be converted 
to a `.css` file and this could be the source for a polymer transformer, by example. 
Consider to use the less transformer as the first in the chain.


#### Transformer Configuration

You can also pass options to less_dart if necessary:

    transformers:
      - less_dart:
          entry_points: 
          	- path/to/builder.less
          	- or/other.less
          output: /path/to/builded.css
          include_path: /path/to/directory/for/less/includes
          compress: true or false
          build_mode: less, dart or mixed. (dart by default)
          other_flags:
            - to include in the lessc command line
          silence: true

- entry_points (or entry_point equivalent):
  - If not supplied process all '*.less' and '*.html' files.
  - Could be a list of files to process, as example: ['web/file1.less', 'web/file2.less'].
  - Could be, also, a pattern for inclusion, as example: ['*.less'].
  - Or have exclusion patterns that start with '!', as example: ['*.less', '!/lib/*.less'].
 
- output - Is the '.css' file generated.
    Only works when one (only one) '.less' file is add to entry_points. No '*' must be found in the path. Is independent from '.html' files.
		If not supplied, or several '.less' are processed, then input file '.less' with extension changed to '.css' is used.
		
- include_path - see [Less Documentation include_path](http://lesscss.org/usage/#command-line-usage-include-paths).

- compress - see [Less Documentation compress](http://lesscss.org/usage/#command-line-usage-compress).

- build_mode -
	- less - command `CMD> lessc --flags input.less output.css` is used. (output.css is in the same directory as input.less)
	- dart - command `CMD> lessc --flags -` with stdin and stdout piped in the dart transformer process. See build folder for the css file.
	- mixed - command `CMD> lessc --flags input.less` with stdout managed by the dart transformer process. See build folder for the css file.
	
- other_flags - Let add other flags such as (--source-map, ...) in the lessc command line.

- silence - Only log error messages to transformer window.


#### Html transformation

When a `.html` file is processed, the transformer look for `<less>...</less>` tags and then the equivalent `<style>...</style>` tags are added below, and at the same level.

All the `<less>` attributes are copied, except 'replace'. With this attribute `<less>` tags are removed in the final file.

The `<less>` tags in the final file are stamped with `style="display:none"` attribute, to avoid conflicts, easing debugging.

A `.html` could have various `<less>...</less>` pairs.

Example for a polymer component:

	<polymer-element name="test">
	  <template>
	    <less>
	      @color: red;
	      :host {
	        background-color: @color;
	      }
	    </less>
	    <div>
			...

Will result in:

	<polymer-element name="test">
	  <template>
	    <less style="display:none">
	      @color: red;
	      :host {
	        background-color: @color;
	      }
	    </less>
	    <style>
	      :host {
	        background-color: red;
	      }
	    </style>
	    <div>
	      ...

## Differences with official (js) version

- Javascript evaluation is not supported. 
  - If this is a problem use [less_node](https://pub.dartlang.org/packages/less_node).
  - Alternatively you can use 'Custom Functions' (see test/custom_functions_test.dart') from your dart program.
- Added option `--banner=bannerfile.txt`.


## Known issues

- The transformer has been rebuild recently. If the new behavior is not right, you could use the previous version:

	      transformers:
	      - less_dart/deprecated/transformer:
	          entry_point: ...

      
- Pass the standard tests in windows (no tested in linux).

- cleanCSS (as plugin) not implemented yet.

- Error color output. Implemented, but not tested in linux. In windows cmd don't support the color commands.


## [License](LICENSE)

Copyright (c) 2009-2015 [Alexis Sellier](http://cloudhead.io/) & The Core Less Team.

Copyright (c) 2014-2015 [Adalberto Lacruz](Adalberto.Lacruz@gmail.com) for dart translation.

Licensed under the [Apache License](LICENSE).
