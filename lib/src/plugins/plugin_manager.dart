//source: less/plugin-manager.js 2.4.0

part of plugins.less;

class PluginManager {
  List<VisitorBase> visitors = [];
  List<ProcessorItem> preProcessors = [];
  List<ProcessorItem> postProcessors = [];
  List<Plugin> installedPlugins = [];
  List<FileManager> fileManagers = [];
  List<FunctionBase> customFunctions = [];

  PluginManager();

  ///
  /// Adds all the plugins in the List
  ///
  //2.4.0 ok
  void addPlugins(List<Plugin> plugins) {
    if (plugins != null) {
      plugins.forEach((plugin) {this.addPlugin(plugin);});
    }

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
  //2.4.0 ok
  void addPlugin(Plugin plugin) {
    this.installedPlugins.add(plugin);
    plugin.install(this);

//2.4.0 ok
//  PluginManager.prototype.addPlugin = function(plugin) {
//      this.installedPlugins.push(plugin);
//      plugin.install(this.less, this);
//  };
  }

  ///
  /// Adds a visitor. The visitor object has options on itself to determine
  /// when it should run.
  ///
  //2.4.0 ok
  void addVisitor(VisitorBase visitor) {
    this.visitors.add(visitor);

//2.4.0
//  PluginManager.prototype.addVisitor = function(visitor) {
//      this.visitors.push(visitor);
//  };
  }

  ///
  /// Adds a [preProcessor] class
  /// [priority] guidelines: 1 = before import, 1000 = import, 2000 = after import
  ///
  //2.4.0 ok
  void addPreProcessor(Processor preProcessor, [int priority = 1000]) {
    int indexToInsertAt;

    for (indexToInsertAt = 0; indexToInsertAt < this.preProcessors.length; indexToInsertAt++) {
      if (this.preProcessors[indexToInsertAt].priority >= priority) break;
    }
    this.preProcessors.insert(
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
  //2.4.0 ok
  void addPostProcessor(Processor postProcessor, [int priority = 1000]) {
    int indexToInsertAt;
    for (indexToInsertAt = 0; indexToInsertAt < this.postProcessors.length; indexToInsertAt++) {
      if (this.postProcessors[indexToInsertAt].priority >= priority) break;
    }
    this.postProcessors.insert(
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
  //2.4.0 ok
  void addFileManager(FileManager manager) {
    this.fileManagers.add(manager);

//2.4.0
//  PluginManager.prototype.addFileManager = function(manager) {
//      this.fileManagers.push(manager);
//  };
  }

  ///
  void addCustomFunctions(FunctionBase custom) {
    this.customFunctions.add(custom);
  }

  ///
  //2.4.0 ok
  List<Processor> getPreProcessors() {
    List<Processor> preProcessors = [];
    this.preProcessors.forEach((item){preProcessors.add(item.preProcessor);});
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
  //2.4.0 ok
  List<Processor> getPostProcessors() {
    List<Processor> postProcessors = [];
    this.postProcessors.forEach((item){postProcessors.add(item.postProcessor);});
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
  //2.4.0 ok
  List<VisitorBase> getVisitors() => this.visitors;

//2.4.0
//  PluginManager.prototype.getVisitors = function() {
//      return this.visitors;
//  };

  ///
  //2.4.0 ok
  List<FileManager> getFileManagers() => this.fileManagers;

//2.4.0
//  PluginManager.prototype.getFileManagers = function() {
//      return this.fileManagers;
//  };

  ///
  List<FunctionBase> getCustomFunction() => this.customFunctions;
}

// *******************************

class ProcessorItem {
  Processor preProcessor;
  Processor postProcessor;
  int priority;

  ProcessorItem({this.preProcessor, this.postProcessor, this.priority});
}