//source: lib/less-node/lessc-helper.js 3.7.1 20180718

library helper.less;

import 'logger.dart';

///
/// helper functions for lessc
///
class LesscHelper {
  /*
   * stylize TODO
   */

  ///
  /// Print command line options
  ///
  static void printUsage() {
    new Logger()
        ..log('usage: lessc [option option=parameter ...] <source> [destination]')
        ..log('')
        ..log("If source is set to `-' (dash or hyphen-minus), input is read from stdin.")
        ..log('')
        ..log('options:')
        ..log('  -h, --help                   Print help (this message) and exit.')
        ..log("  --include-path=PATHS         Sets include paths. Separated by `:'. `;' also supported on windows.")
        ..log('  -M, --depends                Output a makefile import dependency list to stdout.')
        ..log('  --no-color                   Disable colorized output.')
        ..log('  --ie-compat                  Enable IE8 compatibility checks.')
        ..log('  --js                         Enable inline JavaScript in less files, but not supported.')
        ..log('  -l, --lint                   Syntax check only (lint).')
        ..log('  -s, --silent                 Suppress output of error messages.')
        ..log('  --strict-imports             Force evaluation of imports.')
        ..log('  --insecure                   Allow imports from insecure https hosts.')
        ..log('  -v, --version                Print version number and exit.')
        ..log('  --verbose                    Be verbose.')
        ..log('  -x, --compress               Compress output by removing some whitespaces.')
        ..log('  --source-map[=FILENAME]      Outputs a v3 sourcemap to the filename (or output filename.map).')
        ..log('  --source-map-rootpath=X      Adds this path onto the sourcemap filename and less file paths.')
        ..log('  --source-map-basepath=X      Sets sourcemap base path, defaults to current working directory.')
        ..log('  --source-map-include-source  Puts the less files into the map instead of referencing them.')
        ..log('  --source-map-inline          Puts the map (and any less files) as a base64 data uri into the output css file.')
        ..log('  --source-map-url=URL         Sets a custom URL to map file, for sourceMappingURL comment')
        ..log('                               in generated CSS file.')
        ..log('  -rp, --rootpath=URL          Set rootpath for url rewriting in relative imports and urls.')
        ..log('                               Works with or without the relative-urls option.')
        ..log('  -ru=, --rewrite-urls=        Rewrites URLs to make them relative to the base less file.')
        ..log("    all|local|off              'all' rewrites all URLs, 'local' just those starting with a '.'")
        ..log('')
        ..log('  -m=, --math=')
        ..log('     always                    Less will eagerly perform math operations always.')
        ..log('     parens-division           Math performed except for division (/) operator')
        ..log('     parens | strict           Math only performed inside parentheses')
        ..log('     strict-legacy             Parens required in very strict terms (legacy --strict-math)')
        ..log('')
        ..log('  -su=on|off                   Allow mixed units, e.g. 1px+1em or 1px*1px which have units')
        ..log('  --strict-units=on|off        that cannot be represented.')
        ..log("  --global-var='VAR=VALUE'     Defines a variable that can be referenced by the file.")
        ..log("  --modify-var='VAR=VALUE'     Modifies a variable already declared in the file.")
        ..log("  --url-args='QUERYSTRING'     Adds params into url tokens (e.g. 42, cb=42 or 'a=1&b=2').")
        ..log('  --plugin=PLUGIN=OPTIONS      Loads a plugin. You can also omit the --plugin= if the plugin begins')
        ..log('                               less-plugin. E.g. the clean css plugin is called less-plugin-clean-css')
        ..log('                               once installed, use either with')
        ..log('                               --plugin=less-plugin-clean-css or just --clean-css')
        ..log('                               specify options afterwards e.g. --plugin=less-plugin-clean-css="advanced"')
        ..log('                               or --clean-css="advanced".')
        ..log('')
        ..log('                               or --clean-css=\"advanced\".')
        ..log('  --clean-css                  Compress output using clean-css.')
        ..log('  --clean-option=opt:val       Pass an option to clean css, using CLI arguments from ')
        ..log('                               https://github.com/GoalSmashers/clean-css e.g.')
        ..log('                               --clean-option=--selectors-merge-mode:ie8')
        ..log('                               and to switch on advanced use --clean-option=--advanced')
        ..log('')
        ..log('-------------------------- Deprecated ----------------')
        ..log('  -sm=on|off               Legacy parens-only math. Use --math')
        ..log('  --strict-math=on|off     ')
        ..log('')
        ..log('  --line-numbers=TYPE          Outputs filename and line numbers.')
        ..log("                               TYPE can be either 'comments', which will output")
        ..log("                               the debug info within comments, 'mediaquery'")
        ..log('                               that will output the information within a fake')
        ..log('                               media query which is compatible with the SASS')
        ..log("                               format, and 'all' which will do both.")
        ..log('')
        ..log('Report bugs to: http://github.com/less/less.js/issues')
        ..log('Home page: <http://lesscss.org/>');
  }
}
