//source: lib/less-node/plugin-loader.js 2.4.0

part of plugins.less;

class PluginLoader {
  Environment environment;
  Logger logger;
  LessOptions options;
  PluginManager pluginManager;

  //Plugins to install
  Map<String, Plugin> installable = {
    'less-plugin-clean-css': new LessPluginCleanCss(),
    'less-plugin-advanced-color-functions': new LessPluginAdvancedColorFunctions()
  };

  ///
  PluginLoader(this.options) {
    this.environment = new Environment();
    this.logger = environment.logger;
//    if (options.pluginManager == null) options.pluginManager = new PluginManager();
//    pluginManager = options.pluginManager;
  }


  ///
  Plugin tryLoadPlugin(String name, String argument) {
    Plugin plugin;

    if (installable.containsKey(name)) {
      plugin = installable[name];
      if (this.compareVersion(plugin.minVersion, LessIndex.version) < 0) {
        logger.log('plugin ${name} requires version ${this.versionToString(plugin.minVersion)}');
        return null;
      }
      plugin.init(options);

      if (argument!= null) {
        try {
          plugin.setOptions(argument);
        } catch (e) {
          logger.log('Error setting options on plugin ${name}\n${e.toString()}');
          return null;
        }
      }
      return plugin;
    }

    return null;

//2.4.0
//  PluginLoader.prototype.tryLoadPlugin = function(name, argument) {
//      var plugin = this.tryRequirePlugin(name);
//      if (plugin) {
//          // support plugins being a function
//          // so that the plugin can be more usable programmatically
//          if (typeof plugin === "function") {
//              plugin = new plugin();
//          }
//          if (plugin.minVersion) {
//              if (this.compareVersion(plugin.minVersion, this.less.version) < 0) {
//                  console.log("plugin " + name + " requires version " + this.versionToString(plugin.minVersion));
//                  return null;
//              }
//          }
//          if (argument) {
//              if (!plugin.setOptions) {
//                  console.log("options have been provided but the plugin " + name + "does not support any options");
//                  return null;
//              }
//              try {
//                  plugin.setOptions(argument);
//              }
//              catch(e) {
//                  console.log("Error setting options on plugin " + name);
//                  console.log(e.message);
//                  return null;
//              }
//          }
//          return plugin;
//      }
//      return null;
//  };
  }

  ///
  int compareVersion(List<int> aVersion, List<int>  bVersion) {
    for (int i = 0; i < aVersion.length; i++) {
      if (aVersion[i] != bVersion[i]) {
        return (aVersion[i] > bVersion[i]) ? -1: 1;
      }
    }
    return 0;

//2.4.0
//  PluginLoader.prototype.compareVersion = function(aVersion, bVersion) {
//      for (var i = 0; i < aVersion.length; i++) {
//          if (aVersion[i] !== bVersion[i]) {
//              return parseInt(aVersion[i]) > parseInt(bVersion[i]) ? -1 : 1;
//          }
//      }
//      return 0;
//  };
  }

  ///
  String versionToString(List<int> version) {
    String versionString = '';
    version.forEach((v){
      versionString += (versionString.isNotEmpty ? '.' : '') + v.toString();
    });

    return versionString;

//2.4.0
//  PluginLoader.prototype.versionToString = function(version) {
//      var versionString = "";
//      for (var i = 0; i < version.length; i++) {
//          versionString += (versionString ? "." : "") + version[i];
//      }
//      return versionString;
//  };
  }

  ///
  //tryRequirePlugin(name) {
//  PluginLoader.prototype.tryRequirePlugin = function(name) {
//      // is at the same level as the less.js module
//      try {
//          return require("../../../" + name);
//      }
//      catch(e) {
//      }
//      // is installed as a sub dependency of the current folder
//      try {
//          return require(path.join(process.cwd(), "node_modules", name));
//      }
//      catch(e) {
//      }
//      // is referenced relative to the current directory
//      try {
//          return require(path.join(process.cwd(), name));
//      }
//      catch(e) {
//      }
//      // unlikely - would have to be a dependency of where this code was running (less.js)...
//      if (name[0] !== '.') {
//          try {
//              return require(name);
//          }
//          catch(e) {
//          }
//      }
//  };
  //}

  ///
  void printUsage(List<Plugin> plugins) {
    plugins.forEach((plugin){plugin.printUsage();});

//2.4.0
//  PluginLoader.prototype.printUsage = function(plugins) {
//      for (var i = 0; i < plugins.length; i++) {
//          var plugin = plugins[i];
//          if (plugin.printUsage) {
//              plugin.printUsage();
//          }
//      }
//  };
  }

  /// Load plugins and custom functions
  void start() {
    if (options.plugins.isNotEmpty || options.customFunctions != null) {
      if (options.pluginManager == null) options.pluginManager = new PluginManager();
      pluginManager = options.pluginManager;

      pluginManager.addPlugins(options.plugins);

      if (options.customFunctions != null) pluginManager.addCustomFunctions(options.customFunctions);
    }
  }
}