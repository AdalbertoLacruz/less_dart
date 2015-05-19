less-plugin-clean-css
=====================

Compresses the css output from less based on clean-css 3.2.5.

-- Partially implemented --

## Usage

In the less command line: --clean-css="--options"

As directive inside the less code: @plugin "clean-css=options";

## Options
By now are usable:

	-b, --keep-line-breaks      	Keep line breaks
	--s0							Remove all special comments, i.e. /*! comment */
	--s1							Remove all special comments but the first one
	--skip-advanced					Disable advanced optimization (more time demanding or less secure)
	--rounding-precision=[N]		Rounds to `N` decimal places. Defaults to 2. -1 disables rounding.
	-c, --compatibility [ie7|ie8]   Force compatibility mode


## Optimizations
See the implemented [optimizations](OPTIMIZATIONS.md).

## [License](LICENSE)

[Clean-css](https://github.com/jakubpawlowicz/clean-css) is released under the MIT License.

Source & original copyright for [less-plugin-clean-css](https://github.com/less/less-plugin-clean-css).

Copyright (c) 2015 [Adalberto Lacruz](https://github.com/AdalbertoLacruz) for dart implementation.

Licensed under the [Apache License](LICENSE).
