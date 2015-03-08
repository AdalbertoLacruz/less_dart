// source: lib/less/functions/function-caller.js 2.4.0

part of functions.less;

class FunctionCaller {
  Contexts context;
  FileInfo currentFileInfo;
  int index;

  /// Method [name] to call
  String name;

  /// Instance reutilitation
  static FunctionCaller cache;

  /// Inner instance classes
  List<FunctionBase> innerCache;
  List<FunctionBase> customCache;
  FunctionBase defaultCache;

  /// instance that has the method to call
  FunctionBase found;

  FunctionCaller._(Contexts context) {
    innerCache = [
      new ColorBlend(),
      new ColorFunctions(),
      new DataUriFunctions(),
      new ImageSizeFunctions(),
      new MathFunctions(),
      new NumberFunctions(),
      new StringFunctions(),
      new SvgFunctions(),
      new TypesFunctions()
      ];
    defaultCache = new DefaultFunc();
  }

  factory FunctionCaller(String name, Contexts context, int index, FileInfo currentFileInfo) {
    if (cache == null) cache = new FunctionCaller._(context);
    cache
      ..name = name.toLowerCase()
      ..context = context
      ..index = index
      ..currentFileInfo = currentFileInfo
      ..found = null;
    if (context.pluginManager != null) {
      cache.customCache = context.pluginManager.getCustomFunction();
    } else {
      cache.customCache = [];
    }
    return cache;
  }

  /// search the method in the instances, return true if found
  bool isValid() {
    List<FunctionBase> inner = innerCache.sublist(0);
    inner.add(context.defaultFunc != null ? context.defaultFunc : defaultCache);
    inner.addAll(customCache);
    found = null;

    for (int i = 0; i < inner.length; i++) {
      if (inner[i].isValid(name)) {
        found = inner[i];
        return true;
      }
    }

    return false;
  }

  call(List args) {
    found.init(context, index, currentFileInfo);
    return found.call(args);
  }

//2.4.0
//var functionCaller = function(name, context, index, currentFileInfo) {
//    this.name = name.toLowerCase();
//    this.func = functionRegistry.get(this.name);
//    this.index = index;
//    this.context = context;
//    this.currentFileInfo = currentFileInfo;
//};
//functionCaller.prototype.isValid = function() {
//    return Boolean(this.func);
//};
//functionCaller.prototype.call = function(args) {
//    return this.func.apply(this, args);
//};

}