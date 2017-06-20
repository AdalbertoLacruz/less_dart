//source: less/plugin-manager.js 2.5.0

part of plugins.less;

///
class PluginManager {
  ///
  List<FunctionBase>  customFunctions = <FunctionBase>[];
  ///
  List<FileManager>   fileManagers = <FileManager>[];
  ///
  bool                isLoaded = false; //true if plugin has been loaded previously
  ///
  List<Plugin>        installedPlugins = <Plugin>[];
  ///
  List<ProcessorItem> postProcessors = <ProcessorItem>[];
  ///
  List<ProcessorItem> preProcessors = <ProcessorItem>[];
  ///
  List<VisitorBase>   visitors = <VisitorBase>[];

  ///
  PluginManager();

  ///
  /// Adds all the plugins in the List
  ///
  void addPlugins(List<Plugin> plugins) {
    if (plugins != null)
        plugins.forEach((Plugin plugin) {
          addPlugin(plugin);
        });

//2.4.0
//  PluginManager.prototype.addPlugins = function(plugins) {
//      if (plugins) {
//          for (var i = 0; i < plugins.length; i++) {
//              this.addPlugin(plugins[i]);
//          }
//      }
//  };
  }

  ///
  /// Install a [plugin]
  ///
  void addPlugin(Plugin plugin) {
    installedPlugins.add(plugin);
    isLoaded = plugin.isLoaded;

    plugin
        ..install(this)
        ..isLoaded = true;
    isLoaded = false;

//2.4.0
//  PluginManager.prototype.addPlugin = function(plugin) {
//      this.installedPlugins.push(plugin);
//      plugin.install(this.less, this);
//  };
  }

  ///
  /// Adds a visitor. The visitor object has options on itself to determine
  /// when it should run.
  ///
  void addVisitor(VisitorBase visitor) {
    if (isLoaded)
        return;
    visitors.add(visitor);

//2.4.0
//  PluginManager.prototype.addVisitor = function(visitor) {
//      this.visitors.push(visitor);
//  };
  }

  ///
  /// Adds a [preProcessor] class
  /// [priority] guidelines: 1 = before import, 1000 = import, 2000 = after import
  ///
  void addPreProcessor(Processor preProcessor, [int priority = 1000]) {
    if (isLoaded)
        return;

    int indexToInsertAt;

    for (indexToInsertAt = 0; indexToInsertAt < preProcessors.length; indexToInsertAt++) {
      if (preProcessors[indexToInsertAt].priority >= priority)
          break;
    }
    preProcessors.insert(
        indexToInsertAt,
        new ProcessorItem(preProcessor: preProcessor, priority: priority));

//2.4.0
//  PluginManager.prototype.addPreProcessor = function(preProcessor, priority) {
//      var indexToInsertAt;
//      for (indexToInsertAt = 0; indexToInsertAt < this.preProcessors.length; indexToInsertAt++) {
//          if (this.preProcessors[indexToInsertAt].priority >= priority) {
//              break;
//          }
//      }
//      this.preProcessors.splice(indexToInsertAt, 0, {preProcessor: preProcessor, priority: priority});
//  };
  }

  ///
  /// Adds a [postProcessor] class
  /// [priority] guidelines: 1 = before compression, 1000 = compression, 2000 = after compression
  ///
  void addPostProcessor(Processor postProcessor, [int priority = 1000]) {
    if (isLoaded)
        return;

    int indexToInsertAt;

    for (indexToInsertAt = 0; indexToInsertAt < postProcessors.length; indexToInsertAt++) {
      if (postProcessors[indexToInsertAt].priority >= priority)
          break;
    }
    postProcessors.insert(
        indexToInsertAt,
        new ProcessorItem(postProcessor: postProcessor, priority: priority));

//2.4.0
//  PluginManager.prototype.addPostProcessor = function(postProcessor, priority) {
//      var indexToInsertAt;
//      for (indexToInsertAt = 0; indexToInsertAt < this.postProcessors.length; indexToInsertAt++) {
//          if (this.postProcessors[indexToInsertAt].priority >= priority) {
//              break;
//          }
//      }
//      this.postProcessors.splice(indexToInsertAt, 0, {postProcessor: postProcessor, priority: priority});
//  };
  }

  ///
  void addFileManager(FileManager manager) {
    if (isLoaded)
        return;
    fileManagers.add(manager);

//2.4.0
//  PluginManager.prototype.addFileManager = function(manager) {
//      this.fileManagers.push(manager);
//  };
  }

  ///
  void addCustomFunctions(FunctionBase custom) {
    // we let load many times, because scope
    customFunctions.add(custom);
  }

  ///
  List<Processor> getPreProcessors() {
    final List<Processor> preProcessors = <Processor>[];
    this.preProcessors.forEach((ProcessorItem item) {
      preProcessors.add(item.preProcessor);
    });
    return preProcessors;

//2.4.0
//  PluginManager.prototype.getPreProcessors = function() {
//      var preProcessors = [];
//      for (var i = 0; i < this.preProcessors.length; i++) {
//          preProcessors.push(this.preProcessors[i].preProcessor);
//      }
//      return preProcessors;
//  };
  }

  ///
  List<Processor> getPostProcessors() {
    final List<Processor> postProcessors = <Processor>[];
    this.postProcessors.forEach((ProcessorItem item) {
      postProcessors.add(item.postProcessor);
    });

    return postProcessors;

//2.4.0
//  PluginManager.prototype.getPostProcessors = function() {
//      var postProcessors = [];
//      for (var i = 0; i < this.postProcessors.length; i++) {
//          postProcessors.push(this.postProcessors[i].postProcessor);
//      }
//      return postProcessors;
//  };
  }

  ///
  List<VisitorBase> getVisitors() => visitors;

//2.4.0
//  PluginManager.prototype.getVisitors = function() {
//      return this.visitors;
//  };

  ///
  List<FileManager> getFileManagers() => fileManagers;

//2.4.0
//  PluginManager.prototype.getFileManagers = function() {
//      return this.fileManagers;
//  };

  ///
  List<FunctionBase> getCustomFunction() => customFunctions;

  ///
  void resetCustomFunction() {
    customFunctions = <FunctionBase>[];
  }
}

// *******************************

///
class ProcessorItem {
  ///
  Processor preProcessor;
  ///
  Processor postProcessor;
  ///
  int       priority;

  ///
  ProcessorItem({this.preProcessor, this.postProcessor, this.priority});
}
