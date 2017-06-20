library less_plugin_advanced_color_functions.plugins.less;

import '../../tree/tree.dart';
import '../plugins.dart';

part 'advanced_color_functions.dart';

///
class LessPluginAdvancedColorFunctions extends Plugin {
  ///
  @override
  void install(PluginManager pluginManager) {
    pluginManager.addCustomFunctions(new AdvancedColorFunctions());
  }

  @override List<int> minVersion = <int>[2,1,0];
}
