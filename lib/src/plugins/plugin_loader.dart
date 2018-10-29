//source: lib/less-node/plugin-loader.js 2.5.0
//source: lib/less/environment/abstract-plugin-loader.js 3.5.0.beta.2 20180630

part of plugins.less;

///
class PluginLoader {
  ///
  Environment   environment;
  ///
  Logger        logger;
  ///
  LessOptions   options;
  ///
  PluginManager pluginManager;

  /// Plugins to install
  Map<String, Plugin> installable = <String, Plugin>{
    'less-plugin-clean-css': new LessPluginCleanCss(),
    'less-plugin-advanced-color-functions': new LessPluginAdvancedColorFunctions()
  };

  ///
  PluginLoader(this.options) {
    environment = new Environment();
    logger = environment.logger;

//    if (options.pluginManager == null) options.pluginManager = new PluginManager();
//    pluginManager = options.pluginManager;
  }

  ///
  /// Add a [plugin] to list of available plugins, with [name]
  /// Example pluginLoader.define('myPlugin', New MyPlugin());
  ///
  void define(String name, Plugin plugin) {
    installable[name] = plugin;
  }

  ///
  Plugin tryLoadPlugin(String name, String argument) {
    Plugin plugin;
    final String prefix = installable.containsKey(name) ? '' : 'less-plugin-';
    final String pluginName = '$prefix$name';
    String defaultMessage;

    if (installable.containsKey(pluginName)) {
      plugin = installable[pluginName];
      if (compareVersion(plugin.minVersion, LessIndex.version) < 0) {
        logger.log('plugin $name requires version ${versionToString(plugin.minVersion)}');
        return null;
      }
      plugin
          ..init(options)
          ..name = name;

      try {
        defaultMessage = 'Error setting options on plugin $name\n}';
        plugin.setOptions(argument);

        defaultMessage = 'Error during @plugin call';
        plugin.use();
      } catch (e) {
        logger.log(e is LessException
          ? e.message
          : defaultMessage);

        return null;
      }
      return plugin;
    }

    return null;

// 3.5.0.beta.2 20180630
//  AbstractPluginLoader.prototype.evalPlugin = function(contents, context, imports, pluginOptions, fileInfo) {
//
//      var loader,
//          registry,
//          pluginObj,
//          localModule,
//          pluginManager,
//          filename,
//          result;
//
//      pluginManager = context.pluginManager;
//
//      if (fileInfo) {
//          if (typeof fileInfo === 'string') {
//              filename = fileInfo;
//          }
//          else {
//              filename = fileInfo.filename;
//          }
//      }
//      var shortname = (new this.less.FileManager()).extractUrlParts(filename).filename;
//
//      if (filename) {
//          pluginObj = pluginManager.get(filename);
//
//          if (pluginObj) {
//              result = this.trySetOptions(pluginObj, filename, shortname, pluginOptions);
//              if (result) {
//                  return result;
//              }
//              try {
//                  if (pluginObj.use) {
//                      pluginObj.use.call(this.context, pluginObj);
//                  }
//              }
//              catch (e) {
//                  e.message = e.message || 'Error during @plugin call';
//                  return new LessError(e, imports, filename);
//              }
//              return pluginObj;
//          }
//      }
//      localModule = {
//          exports: {},
//          pluginManager: pluginManager,
//          fileInfo: fileInfo
//      };
//      registry = functionRegistry.create();
//
//      var registerPlugin = function(obj) {
//          pluginObj = obj;
//      };
//
//      try {
//          loader = new Function('module', 'require', 'registerPlugin', 'functions', 'tree', 'less', 'fileInfo', contents);
//          loader(localModule, this.require(filename), registerPlugin, registry, this.less.tree, this.less, fileInfo);
//      } catch (e) {
//          return new LessError(e, imports, filename);
//      }
//
//      if (!pluginObj) {
//          pluginObj = localModule.exports;
//      }
//      pluginObj = this.validatePlugin(pluginObj, filename, shortname);
//
//      if (pluginObj instanceof LessError) {
//          return pluginObj;
//      }
//
//      if (pluginObj) {
//          // For 2.x back-compatibility - setOptions() before install()
//          pluginObj.imports = imports;
//          pluginObj.filename = filename;
//          result = this.trySetOptions(pluginObj, filename, shortname, pluginOptions);
//          if (result) {
//              return result;
//          }
//
//          // Run on first load
//          pluginManager.addPlugin(pluginObj, fileInfo.filename, registry);
//          pluginObj.functions = registry.getLocalFunctions();
//
//          // Need to call setOptions again because the pluginObj might have functions
//          result = this.trySetOptions(pluginObj, filename, shortname, pluginOptions);
//          if (result) {
//              return result;
//          }
//
//          // Run every @plugin call
//          try {
//              if (pluginObj.use) {
//                  pluginObj.use.call(this.context, pluginObj);
//              }
//          }
//          catch (e) {
//              e.message = e.message || 'Error during @plugin call';
//              return new LessError(e, imports, filename);
//          }
//
//      }
//      else {
//          return new LessError({ message: 'Not a valid plugin' }, imports, filename);
//      }
//
//      return pluginObj;
//
//  };
  }

  ///
  /// Compares the less version required by the plugin
  /// Returns -1, 0, +1
  ///
  // String (as js version) not supported in aVersion for simplicity
  int compareVersion(List<int> aVersion, List<int> bVersion) {
    for (int i = 0; i < aVersion.length; i++) {
      if (aVersion[i] != bVersion[i]) {
        return (aVersion[i] > bVersion[i]) ? -1 : 1;
      }
    }
    return 0;

//3.0.0 20160713
// AbstractPluginLoader.prototype.compareVersion = function(aVersion, bVersion) {
//     if (typeof aVersion === "string") {
//         aVersion = aVersion.match(/^(\d+)\.?(\d+)?\.?(\d+)?/);
//         aVersion.shift();
//     }
//     for (var i = 0; i < aVersion.length; i++) {
//         if (aVersion[i] !== bVersion[i]) {
//             return parseInt(aVersion[i]) > parseInt(bVersion[i]) ? -1 : 1;
//         }
//     }
//     return 0;
// };
  }

  ///
  /// Transforms a int version list to String
  ///
  /// Example: [1,2,3] => '1.2.3'
  ///
  String versionToString(List<int> version) => version.join('.');

//2.4.0
//  PluginLoader.prototype.versionToString = function(version) {
//      var versionString = "";
//      for (var i = 0; i < version.length; i++) {
//          versionString += (versionString ? "." : "") + version[i];
//      }
//      return versionString;
//  };

  ///
  void printUsage(List<Plugin> plugins) {
    plugins.forEach((Plugin plugin) {
      plugin.printUsage();
    });

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

  /// Load plugins
  void start() {
    if (options.plugins.isNotEmpty) {
      options.pluginManager ??= new PluginManager();
      pluginManager = options.pluginManager
          ..addPlugins(options.plugins);
    }
  }
}
