## Native Dart Less compiler/builder/compressor for .less files and html style tags to css

[Less](http://lesscss.org/)-builder for [webdev serve](https://webdev.dartlang.org/tools/webdev#serve), [webdev build](https://webdev.dartlang.org/tools/webdev#build) and Less-compiler for [pub-run](https://www.dartlang.org/tools/pub/cmd/pub-run)

This is a translation from Less 3.9.0 Javascript (over nodejs) to Dart.
It is a pure Dart implementation for the server/developer side.
The minimum dart sdk supported is 2.0.

As builder could work also with `.html` files, by converting `<less>` tags to `<style>` tags.


## Use as Compiler or Builder

The package is a Less compiler with wrappers for use in command line or as a dart
builder. Also, it could be used in other Dart programs.


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
        args.add('--math=always');
        args.add('--strict-units=on');
        args.add('less/charsets.less');
        less.transform(args).then((exitCode){
          stderr.write(less.stderr.toString());
          stdout.writeln('\nstdout:');
          stdout.write(less.stdout.toString());
        });
      }


### Use as a Dart Builder with webdev build or webdev serve

Add the following lines to your `pubspec.yaml`:

    dependencies:
      less_dart: any

Also, you will need a `build.yaml` file, with the configuration options.

One of them is the entry_points, to specify what files must be transformed. Could be:

    entry_points: ['*.less', '*.html']

After that, all your `.less` files will be automatically transformed to corresponding `.css` files.
Also the `.less.html` files will be processed.
The standard default is `*.less`, but it could be modified by inclusion or exclusion paths.
The exclusion path start with `!`. And `*` is supported in the paths.

The power of Dart builder is to chain builders, so a `.less` file will be converted
to a `.css` file and this could be the source for another builder.
Consider to use the less builder as the first in the chain.

#### builder.yaml Configuration

In order to use the less builder, you must configure it:

    targets:
      $default:
        builders:
          less_dart:
            options:
              entry_points: ['path/to/file.less', 'or/other/file.less', 'path/to/file.less.html']
              include_path: 'path/to/directory/for/less/includes'
              cleancss: true or false or "option1 option2"
              compress: true or false
              other_flags: ['to include in the lessc command line', ...]
          less_dart|less_source_cleanup:
            options:
              enabled: true or false

- entry_points (entry_point is equivalent):
  - If not supplied process all `*.less` files.
  - Could be a list of files to process, such as: `['web/file1.less', 'web/file2.less']`.
  - Could be, also, a pattern for inclusion, as for example: `['*.less']`.
  - Or have exclusion patterns that start with '!', such as: `['*.less', '!/lib/*.less']`.

The output file will have the same name as the input, with `.css` extension for less.
For html the `file.less.html` will be `file.html`.

- include_path - see [Less Documentation include_path](http://lesscss.org/usage/#command-line-usage-include-paths).

- cleancss - Compress/optimize with clean-css plugin.
	- true: Use default options
	- "option1 option2..." Specifies options to be used.
	- See [Plugin Info](lib/src/plugins/less_plugin_clean_css/README.md).

- compress - see [Less Documentation compress](http://lesscss.org/usage/#command-line-usage-compress).

- other_flags - Let add other flags such as (--source-map, ...) in the lessc command line.

less_source_cleanup is a post-builder that clean the `*.less` and `*.less.html` files in the build directory.
It could be

- enabled - true/false

#### Html transformation

When a `.less.html` file is builded, the transformer look for `<less>...</less>` tags and then the equivalent `<style>...</style>` tags are added below, and at the same level.

All the `<less>` attributes are copied, except 'replace'. With this attribute `<less>` tags are removed in the final file.

The `<less>` tags in the final file are stamped with `style="display:none"` attribute, to avoid conflicts, easing debugging.

A `.less.html` could have various `<less>...</less>` pairs.

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


## Custom Builder, Custom Plugin, Custom Functions
You could clone the package to your local environment and modify it to add plugins. But, ...

Other way, is to inherit the builder in your project. Create a file
`lib\my_builder.dart` which extends the less_dart `LessBuilder` (see example in: `example\less_custom_builder.dart`).
The `customOptions` method could be override to modify the less options defining a custom plugin with custom functions.


## Differences with official (js) version

- Javascript evaluation is not supported.
  - Alternatively you can use 'Custom Functions' (see example in: `example/custom_functions_example.dart`) from your dart project, or your custom builder.
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

- cleanCSS (as plugin) not fully implemented.

- Error color output. In windows cmd don't support the color commands. [ConEmu](https://conemu.github.io/) is an alternative.

## Contribuitors
[DisDis](https://github.com/DisDis)

## [License](LICENSE)

Copyright (c) 2009-2018 [Alexis Sellier](http://cloudhead.io/) & The Core Less Team.

Copyright (c) 2014-2018 [Adalberto Lacruz](https://github.com/AdalbertoLacruz) for dart translation.

Licensed under the [Apache License](LICENSE).
