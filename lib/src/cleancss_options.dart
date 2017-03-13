library cleancss.less;

import 'logger.dart';

class CleancssOptions {
  bool keepBreaks;
  int keepSpecialComments;
  bool noAdvanced;
  String compatibility;
  int roundingPrecision;

  Logger console = new Logger();
  bool parseError = false;

  CleancssOptions();

  /*
   * Update cleancss options from command
   * ej.: --compatibility:ie7
   */
  bool parse(String command) {
    if (command == null) return setParseError('empty');
    List<String> cleanOptionArgs = command.split(":");

    switch(cleanOptionArgs[0]) {
      case "--keep-line-breaks":
      case "-b":
        this.keepBreaks = true;
        break;
      case "--s0":
        // Remove all special comments, i.e. /*! comment */
        this.keepSpecialComments = 0;
        break;
      case "--s1":
        // Remove all special comments but the first one
        this.keepSpecialComments = 1;
        break;
      case "--skip-advanced":
        //Disable advanced optimizations - selector & property merging, reduction, etc.
        this.noAdvanced = true;
        break;
      case "--advanced":
        this.noAdvanced = false;
        break;
      case "--compatibility":
        // Force compatibility mode [ie7|ie8]
        if (cleanOptionArgs.length < 2) return setParseError(cleanOptionArgs[0]);
        if (cleanOptionArgs[1] == '') return setParseError(cleanOptionArgs[0]);
        this.compatibility = cleanOptionArgs[1];
        break;
      case "--rounding-precision":
        // Rounds pixel values to `N` decimal places, defaults to 2
        if (cleanOptionArgs.length < 2) return setParseError(cleanOptionArgs[0]);
        try {
          this.roundingPrecision = int.parse(cleanOptionArgs[1]);
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
    console.log('unrecognised clean-css option $option');
    console.log("we support only arguments that make sense for less, '--keep-line-breaks', '-b'");
    console.log("'--s0', '--s1', '--advanced', '--skip-advanced', '--compatibility', '--rounding-precision'");
    parseError = true;
    return false;
  }
}
