//source: less-plugin-clean-css/lib/parse-options.js

part of less_plugin_clean_css.plugins.less;

class CleanCssOptions extends PluginOptions {
  /// set to false to disable advanced optimizations - selector & property merging, reduction, etc.
  bool                  advanced = true;

  /// set to false to disable aggressive merging of properties.
  bool                  aggressiveMerging = true;

  /// enables compatibility mode: ie7, ie8 *
  CleanCssCompatibility compatibility;

  /// whether to keep line breaks (default is false)
  bool                  keepBreaks = false;

  /// * for keeping all (default), 1 for keeping first one only, 0 for removing all
  String                keepSpecialComments = '*';

  /// set to false to skip URL rebasing
  bool                  rebase = true;

  /// defaults to 2; -1 disables rounding
  int                   roundingPrecision = 2;

  /// set to false to skip shorthand compacting (default is true unless sourceMap is set when it's false)
  bool                  shorthandCompacting = true;


  CleanCssOptions(String cmdOptions) {
    String              argName;
    List<String>        argSplit;
    final List<String>  cleanOptionArgs = cmdOptions.split(' ');
    String              compatibilitySource = '';
    final RegExp        reName = new RegExp(r'^-+');

    for (int i = 0; i < cleanOptionArgs.length; i++) {
      argSplit = cleanOptionArgs[i].split('=');
      argName = argSplit[0].replaceFirst(reName, '');

      switch (argName) {
        case '': //defaults
          break;
        case 'keep-line-breaks':
        case 'b':
          keepBreaks = true;
          break;
        case 's0':
          keepSpecialComments = '0';
          break;
        case 's1':
          keepSpecialComments = '1';
          break;
        case 'keepSpecialComments':
          final String specialCommentOption = argSplit[1];
          if (specialCommentOption != '*') {
            keepSpecialComments = int.parse(specialCommentOption).toString();
          }
          break;
        case 'skip-advanced':
          advanced = false;
          break;
        case 'advanced':
          advanced = true;
          break;
        case 'skip-rebase':
          rebase = false;
          break;
        case 'rebase':
          rebase = true;
          break;
        case 'skip-aggressive-merging':
          aggressiveMerging = false;
          break;
        case 'skip-shorthand-compacting':
          shorthandCompacting = false;
          break;
        case 'c':
        case 'compatibility':
          compatibilitySource = argSplit[1];
          break;
        case 'rounding-precision':
          roundingPrecision = int.parse(argSplit[1]);
          break;
        default:
          throw new UnsupportedError("unrecognised clean-css option '${argSplit[0]}'");
      }
    }
    compatibility = new CleanCssCompatibility(compatibilitySource);
  }
}

//2.4.0
//if (typeof options === 'string') {
//    var cleanOptionArgs = options.split(" ");
//    options = {};
//    for(var i = 0; i < cleanOptionArgs.length; i++) {
//        var argSplit = cleanOptionArgs[i].split("="),
//            argName = argSplit[0].replace(/^-+/,"");
//        switch(argName) {
//            case "keep-line-breaks":
//            case "b":
//                options.keepBreaks = true;
//                break;
//            case "s0":
//                options.keepSpecialComments = 0;
//                break;
//            case "s1":
//                options.keepSpecialComments = 1;
//                break;
//            case "keepSpecialComments":
//                var specialCommentOption = argSplit[1];
//                if (specialCommentOption !== "*") {
//                    specialCommentOption = Number(specialCommentOption);
//                }
//                options.keepSpecialComments = specialCommentOption;
//                break;
//            // for compatibility - does nothing
//            case "skip-advanced":
//                options.advanced = false;
//                break;
//            case "advanced":
//                options.advanced = true;
//                break;
//            case "skip-rebase":
//                options.rebase = false;
//                break;
//            case "rebase":
//                options.rebase = true;
//                break;
//            case "skip-aggressive-merging":
//                options.aggressiveMerging = false;
//                break;
//            case "skip-shorthand-compacting":
//                options.shorthandCompacting = false;
//                break;
//            case "c":
//            case "compatibility":
//                options.compatibility = argSplit[1];
//                break;
//            case "rounding-precision":
//                options.roundingPrecision = Number(argSplit[1]);
//                break;
//            default:
//                throw new Error("unrecognised clean-css option '" + argSplit[0] + "'");
//        }
//    }
//}
//return options;
