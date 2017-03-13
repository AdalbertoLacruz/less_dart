//source: less/functions/function-registry.js 2.5.0 - partially

part of functions.less;

///
/// Manages the custom functions defined by plugins
///
class FunctionRegistry {
  static List<FunctionBase> globalFunctions = <FunctionBase>[];  //imported by plugin at root

  FunctionRegistry    base; //parent
  List<FunctionBase>  cache;
  List<FunctionBase>  data = <FunctionBase>[]; //scoped functions

  FunctionRegistry._(this.base);

  factory FunctionRegistry.inherit(FunctionRegistry base) {
    return new FunctionRegistry._(base);
  }

  ///
  /// Search in context.frames the first FunctionRegistry != null
  /// [frames] is VariableMixin = Directive | Media | MixinDefinition | Ruleset
  ///
  static FunctionRegistry foundInherit(List<Node> frames) {
    VariableMixin frame;
    for (int i = 0; i < frames.length; i++) {
      frame = frames[i];
      if (frame.functionRegistry != null) return frame.functionRegistry;
    }
    return null;
  }

  ///
  /// add the @plugin [functions]
  ///
  void add(List<FunctionBase> functions) {
    if (functions != null) data.addAll(functions); //add to data and cache if not null
  }

  ///
  /// Return the full list of functions, traversing the tree until the root
  ///
  List<FunctionBase> get() {
    if (cache == null) {
      cache = data;
      if (base != null) {
        cache.addAll(base.get());
      } else {
        if (globalFunctions != null) cache.addAll(globalFunctions);
      }
    }
    return cache;
  }

  ///
  /// Forces reevaluate the cache next time
  ///
  void resetCache() {
    cache = null;
  }
}

//2.4.0 20150305
//function makeRegistry( base ) {
//    return {
//        _data: {},
//        add: function(name, func) {
//            // precautionary case conversion, as later querying of
//            // the registry by function-caller uses lower case as well.
//            name = name.toLowerCase();
//
//            if (this._data.hasOwnProperty(name)) {
//                //TODO warn
//            }
//            this._data[name] = func;
//        },
//        addMultiple: function(functions) {
//            Object.keys(functions).forEach(
//                function(name) {
//                    this.add(name, functions[name]);
//                }.bind(this));
//        },
//        get: function(name) {
//            return this._data[name] || ( base && base.get( name ));
//        },
//        inherit : function() {
//            return makeRegistry( this );
//        }
//    };
//}
