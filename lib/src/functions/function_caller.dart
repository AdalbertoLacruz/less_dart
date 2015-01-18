// source: lib/less/functions/function-caller.js 2.2.0

part of functions.less;

class FunctionCaller {
  Env context;
  FileInfo currentFileInfo;
  int index;

  /// Method [name] to call
  String name;

  /// Instance reutilitation
  static FunctionCaller cache;

  /// Inner instance classes
  List<FunctionBase> innerCache;
  FunctionBase defaultCache;

  /// instance that has the method to call
  FunctionBase found;

  FunctionCaller._() {
    innerCache = [
      new ColorBlend(),
      new ColorFunctions(),
      new DataUriFunctions(),
      new MathFunctions(),
      new NumberFunctions(),
      new StringFunctions(),
      new SvgFunctions(),
      new TypesFunctions()
      ];
    defaultCache = new DefaultFunc();
  }

  factory FunctionCaller(String name, Env context, int index, FileInfo currentFileInfo) {
    if (cache == null) cache = new FunctionCaller._();
    cache
      ..name = name.toLowerCase()
      ..context = context
      ..index = index
      ..currentFileInfo = currentFileInfo
      ..found = null;
    return cache;
  }

  /// search the method in the instances, return true if found
  bool isValid() {
    List<FunctionBase> inner = innerCache.sublist(0);
    inner.add(context.defaultFunc != null ? context.defaultFunc : defaultCache);
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