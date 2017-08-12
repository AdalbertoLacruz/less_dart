// source: lib/less/functions/function-caller.js 3.0.0 20170607

part of functions.less;

///
class FunctionCaller {
  ///
  Contexts  context;
  ///
  FileInfo  currentFileInfo;
  ///
  int       index;

  /// Instance reutilitation
  static FunctionCaller cache;

  /// Method [name] to call
  String name;

  /// Inner instance classes
  List<FunctionBase>  innerCache;
  ///
  List<FunctionBase>  customCache;
  ///
  FunctionBase        defaultCache;

  /// Instance that has the method to call
  FunctionBase found;

  ///
  factory FunctionCaller(String name, Contexts context, int index, FileInfo currentFileInfo) {
    cache ??= new FunctionCaller._(context);

    return cache
      ..name = name.toLowerCase()
      ..context = context
      ..index = index
      ..currentFileInfo = currentFileInfo
      ..found = null
      ..customCache = (context.frames != null)
          ? (context.frames[0] as VariableMixin).functionRegistry.get()
          : <FunctionBase>[];
  }

  ///
  FunctionCaller._(Contexts context) {
    innerCache = <FunctionBase>[
      new BooleanFunctions(),
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

//2.4.0 20150305
//  var functionCaller = function(name, context, index, currentFileInfo) {
//      this.name = name.toLowerCase();
//      this.index = index;
//      this.context = context;
//      this.currentFileInfo = currentFileInfo;
//
//      this.func = context.frames[0].functionRegistry.get(this.name);
//  };
  }

  ///
  /// Search the method in the instances, return true if found
  ///
  bool isValid() {
    final List<FunctionBase> inner = innerCache.sublist(0)
        ..add(context.defaultFunc != null ? context.defaultFunc : defaultCache)
        ..addAll(customCache);
    found = null;

    for (int i = 0; i < inner.length; i++) {
      if (inner[i].isValid(name)) {
        found = inner[i];
        return true;
      }
    }

    return false;

//2.4.0
//functionCaller.prototype.isValid = function() {
//    return Boolean(this.func);
//};
  }

  ///
  dynamic call(List<Node> args) {
    // This code is terrible and should be replaced as per this issue...
    // https://github.com/less/less.js/issues/2477

    List<Node> _args = args;

    if (_args?.isNotEmpty ?? false) {
      _args.retainWhere((Node item) => item is! Comment);
      _args = _args.map((Node item) {
        if (item is Expression) {
          final List<Node> subNodes = item.value
              ..retainWhere((Node item) => item is! Comment);

          if (subNodes.length == 1) {
            return subNodes[0];
          } else {
            return new Expression(subNodes);
          }
        }
        return item;
      }).toList();
    }

    found.init(context, index, currentFileInfo);
    return found.call(_args);

//2.4.0+2
//  functionCaller.prototype.call = function(args) {
//
//      // This code is terrible and should be replaced as per this issue...
//      // https://github.com/less/less.js/issues/2477
//      if (Array.isArray(args)) {
//          args = args.filter(function (item) {
//              if (item.type === "Comment") {
//                  return false;
//              }
//              return true;
//          })
//          .map(function(item) {
//              if (item.type === "Expression") {
//                  var subNodes = item.value.filter(function (item) {
//                      if (item.type === "Comment") {
//                          return false;
//                      }
//                      return true;
//                  });
//                  if (subNodes.length === 1) {
//                      return subNodes[0];
//                  } else {
//                      return new Expression(subNodes);
//                  }
//              }
//              return item;
//          });
//      }
//
//      return this.func.apply(this, args);
//  };
  }
}
