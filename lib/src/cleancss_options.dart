library cleancss.less;

import 'logger.dart';

class CleancssOptions {
  String  compatibility;
  Logger  console = new Logger();
  bool    keepBreaks;
  int     keepSpecialComments;
  bool    noAdvanced;
  bool    parseError = false;
  int     roundingPrecision;

  CleancssOptions();

  /*
   * Update cleancss options from command
   * ej.: --compatibility:ie7
   */
  bool parse(String command) {
    if (command == null)
        return setParseError('empty');
    final List<String> cleanOptionArgs = command.split(":");

    switch (cleanOptionArgs[0]) {
      case "--keep-line-breaks":
      case "-b":
        keepBreaks = true;
        break;
      case "--s0":
        // Remove all special comments, i.e. /*! comment */
        keepSpecialComments = 0;
        break;
      case "--s1":
        // Remove all special comments but the first one
        keepSpecialComments = 1;
        break;
      case "--skip-advanced":
        //Disable advanced optimizations - selector & property merging, reduction, etc.
        noAdvanced = true;
        break;
      case "--advanced":
        noAdvanced = false;
        break;
      case "--compatibility":
        // Force compatibility mode [ie7|ie8]
        if (cleanOptionArgs.length < 2)
            return setParseError(cleanOptionArgs[0]);
        if (cleanOptionArgs[1] == '')
            return setParseError(cleanOptionArgs[0]);
        compatibility = cleanOptionArgs[1];
        break;
      case "--rounding-precision":
        // Rounds pixel values to `N` decimal places, defaults to 2
        if (cleanOptionArgs.length < 2)
            return setParseError(cleanOptionArgs[0]);
        try {
          roundingPrecision = int.parse(cleanOptionArgs[1]);
        } catch (e) {
          return setParseError(cleanOptionArgs[0]);
        }
        break;
      default:
        return setParseError(cleanOptionArgs[0]);
    }
    return true;
  }

  ///
  bool setParseError(String option) {
    console
        ..log('unrecognised clean-css option $option')
        ..log("we support only arguments that make sense for less, '--keep-line-breaks', '-b'")
        ..log("'--s0', '--s1', '--advanced', '--skip-advanced', '--compatibility', '--rounding-precision'");
    parseError = true;
    return false;
  }
}
