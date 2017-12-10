## Native Dart Less compiler/transformer/compressor for .less files and html style tags to css

[Less](http://lesscss.org/)-transformer for [pub-serve](http://pub.dartlang.org/doc/pub-serve.html), [pub-build](http://pub.dartlang.org/doc/pub-build.html) and Less-compiler for [pub-run](https://www.dartlang.org/tools/pub/cmd/pub-run.html)

This is a translation from Less 3.0.0.-alpha.3 Javascript (over nodejs) to Dart.
It is a pure Dart implementation for the server/developer side.

As transformer could work also with `.html` files, by converting `<less>` tags to `<style>` tags.


## Use as Compiler or Transformer

The package is a Less compiler with wrappers for use in command line or as a dart
transformer. Also, it could be used in other Dart programs.


### Pub-run usage

If you get the full distribution (tar.gz file), the bin directory has the `lessc.dart` file
for use with pub run:

    CMD> pub run bin/lessc [args] file.less file.css

A working example: `CMD> pub run bin/lessc test/less/charsets.less`

Example with error output: `CMD> pub run bin/lessc --no-color test/less/errors/import-subfolder1.less`

For help: `CMD> pub run bin/lessc --help`


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

The power of Dart builder is to chain transformers, so a `.less` file will be converted
to a `.css` file and this could be the source for a polymer transformer, as an example.
Consider to use the less transformer as the first in the chain.

When pub build is started, a change in a `.less` file, or a `.html` file detected as entry point, trigger the transformer process again.


#### Transformer Configuration

You can also pass options to less_dart if necessary:

    transformers:
      - less_dart:
          entry_points:
          	- path/to/builder.less
          	- or/other.less
          output: /path/to/builded.css
          include_path: /path/to/directory/for/less/includes
		  cleancss: trur or false or "option1 option2"
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

- cleancss - Compress/optimize with clean-css plugin.
	- true: Use default options
	- "option1 option2..." Specifies options to be used.
	- See [Plugin Info](lib/src/plugins/less_plugin_clean_css/README.md).


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

Also, you could use `<style type="text/less">...</style>` as equivalent to `<less replace>...</less>`.

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


## Custom Transformer, Custom Plugin, Custom Functions
You could clone the package to your local environment and modify it to add plugins. But, ...

Other way, is to inherit the transformer in your application. Create a file
`lib\transformer.dart` which extends the less_dart `FileTransformer` (see example in: `test\custom_transformer.dart`). The `customOptions` method could be override to modify the less options defining a custom plugin with custom functions.


## Differences with official (js) version

- Javascript evaluation is not supported.
  - If this is a problem use [less_node](https://pub.dartlang.org/packages/less_node).
  - Alternatively you can use 'Custom Functions' (see example in: `test/custom_functions_test.dart`) from your dart program, or your custom transformer.
- Added option `--banner=bannerfile.txt`.
- Added directive `@options "--flags";`. Intended to be the first line in a less file/tag, acts globally. This directive let specify individual options in batch processing. Example: `@options "--strict-math=on --strict-units=on --include-path=test/data";`.
- Modified directive `@plugin "lib";`. lib is the plugin name and must exist as dart code in the plugins directory. By now are operative `@plugin "less-plugin-advanced-color-functions";`  and `@plugin "less-plugin-clean-css"` partially. You could define your custom plugins as indicated above.
- Basic support for Custom CSS mixins as used by Polymer 1.0.
  - `--mixin-name: {...}`
  - `@apply(--mixin-name);`
- Function rem to convert from px, pt or em to rem, defined as rem(fontSize, [baseFont]):
  - `rem(16), rem(16px), rem(12pt), rem(1em), rem(20, 20)`
  - `1rem, 1rem, 1rem, 1rem, 1rem`
- @import supports packages as source:
  - `@import "packages/package-name/path/starting-in-lib";`
  - `@import "package://package-name/path/starting-in-lib";`

  Also, option `--include-path` supports package, for easy use of shared mixins libraries:
  - `--include-path=packages/package-name/path/starting-in-lib`
  - `--include-path=package://package-name/path/starting-in-lib`


## Known issues

- The transformer has complex funcionality. There is an older and simpler version.

	      transformers:
	      - less_dart/deprecated/transformer:
	          entry_point: ...

- cleanCSS (as plugin) not fully implemented.

- Error color output. In windows cmd don't support the color commands. [ConEmu](https://conemu.github.io/) is an alternative.

## Contribuitors
[DisDis](https://github.com/DisDis)

## [License](LICENSE)

Copyright (c) 2009-2017 [Alexis Sellier](http://cloudhead.io/) & The Core Less Team.

Copyright (c) 2014-2017 [Adalberto Lacruz](https://github.com/AdalbertoLacruz) for dart translation.

Licensed under the [Apache License](LICENSE).
