part of functions.less;

///
/// Implements the mechanism to call a method by string
///
class FunctionBase {
  /// Method registry: { 'externalName': {'name': internalName, 'listArguments': false}  }
  Map<String, FunctionRegistryItem> registry = {};

  int index;
  FileInfo currentFileInfo;
  Env context;
  String name;

  FunctionBase() {
    ClassMirror classMirror = reflect(this).type;
    defineMethod annotation;
    bool listArguments;
    String externalName;
    String internalName;
    FunctionRegistryItem item;
    List<InstanceMirror> metadataList;

    for (var method in classMirror.declarations.values) {
      listArguments = false;
      externalName = internalName = MirrorSystem.getName(method.simpleName);
      metadataList = method.metadata;
      if (metadataList.isNotEmpty) {
        annotation = metadataList.first.reflectee;
        if (annotation.skip) continue;
        if (annotation.name != null) externalName = annotation.name;
        listArguments = annotation.listArguments;
      }
      item = new FunctionRegistryItem(internalName, listArguments);
      if (method is MethodMirror && !method.isConstructor) {
        registry[externalName] = item;
      }
    }
  }

  /// Config functions with the necessarry information for processing
  init(context, index, currentFileInfo) {
    this.context = context;
    this.index = index;
    this.currentFileInfo = currentFileInfo;
  }


  /// Check name is a method name available
  bool isValid(String name) {
    bool hasMethod = registry.containsKey(name);
    this.name = hasMethod ? name : null;
    return hasMethod;
  }

  /// Call the last valid name of method
  call(List args) {
    if (this.name == null) return null;

    FunctionRegistryItem item = registry[this.name];
    List arguments = item.listArguments ? [args] : args;
    InstanceMirror instanceMirror = reflect(this);
    return instanceMirror.invoke(new Symbol(item.name), arguments).reflectee;
  }
}


///
/// Annotation class for exceptions to method definition
///
class defineMethod {
  /// [skip] controls if the method is included in the registry.
  /// Example: Internal methods as 'isValid' or 'call'.
  final bool skip;

  /// external [name] used to call the method.
  /// Example: '%' as external name, and 'format' as method name.
  final String name;

  /// [listArguments] let pass all the arguments as list.
  /// Example: [arg1, arg2, ... argN] in a min(...) method.
  final bool listArguments;

  const defineMethod({this.name, this.skip: false, this.listArguments: false});
}

/// Item defining a method in the function registry
class FunctionRegistryItem {
  /// Internal method name
  String name;

  /// Pass arguments as list
  bool listArguments;

  FunctionRegistryItem(this.name, this.listArguments);
}
