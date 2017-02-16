library less_plugin_advanced_color_functions.plugins.less;

import '../plugins.dart';
import '../../tree/tree.dart';

part 'advancedColorFunctions.dart';

class LessPluginAdvancedColorFunctions extends Plugin {

  ///
  install(PluginManager pluginManager) {
    FunctionBase advancedColorFunctions = new AdvancedColorFunctions();
    pluginManager.addCustomFunctions(advancedColorFunctions);
  }

  @override
  List<int> minVersion = [2,1,0];
}