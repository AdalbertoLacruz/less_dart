part of functions.less;
///
/// Implements the way to call a method by string
///
class FunctionBase {
  /// Method registry: { 'externalName': {'name': internalName, 'listArguments': false}  }
  Map<String, FunctionRegistryItem> registry = <String, FunctionRegistryItem>{};

  Contexts  context;
  FileInfo  currentFileInfo;
  int       index;
  String    name;

  FunctionBase() {
    DefineMethod          annotation;
    final ClassMirror     classMirror = reflect(this).type;
    String                externalName;
    String                internalName;
    FunctionRegistryItem  item;
    bool                  listArguments;
    List<InstanceMirror>  metadataList;

    for (DeclarationMirror method in classMirror.declarations.values) {
      listArguments = false;
      externalName = internalName = MirrorSystem.getName(method.simpleName);
      metadataList = method.metadata;
      if (metadataList.isNotEmpty) {
        annotation = metadataList.first.reflectee;
        if (annotation.skip)
            continue;
        if (annotation.name != null)
            externalName = annotation.name;
        listArguments = annotation.listArguments;
      }
      item = new FunctionRegistryItem(internalName, listArguments);
      if (method is MethodMirror && !method.isConstructor)
          registry[externalName] = item;
    }
  }

  ///
  /// Config functions with the necessarry information for processing
  ///
  void init(Contexts context, int index, FileInfo currentFileInfo) {
    this.context = context;
    this.index = index;
    this.currentFileInfo = currentFileInfo;
  }

  ///
  /// Check if name is a method name available
  ///
  bool isValid(String name) {
    final bool hasMethod = registry.containsKey(name);
    this.name = hasMethod ? name : null;
    return hasMethod;
  }

  ///
  /// Call the last valid name of method
  ///
  dynamic call(List<Node> args) {
    if (name == null) 
        return null;

    final FunctionRegistryItem item = registry[name];
    final List<dynamic> arguments = item.listArguments ? <List<Node>>[args] : args;
    final InstanceMirror instanceMirror = reflect(this);

    return instanceMirror.invoke(new Symbol(item.name), arguments).reflectee;
  }
}

const DefineMethod defineMethodSkip = const DefineMethod(skip: true);
const DefineMethod defineMethodListArguments = const DefineMethod(listArguments: true);

///
/// Annotation class for exceptions to method definition
///
class DefineMethod {
  /// [skip] controls if the method is included in the registry.
  /// Example: Internal methods as 'isValid' or 'call'.
  final bool    skip;

  /// external [name] used to call the method.
  /// Example: '%' as external name, and 'format' as method name.
  final String  name;

  /// [listArguments] let pass all the arguments as list.
  /// Example: [arg1, arg2, ... argN] in a min(...) method.
  final bool    listArguments;

  const DefineMethod({this.name, this.skip: false, this.listArguments: false});
}

/// Item defining a method in the function registry
class FunctionRegistryItem {
  /// Internal method name
  String  name;

  /// Pass arguments as list
  bool    listArguments;

  FunctionRegistryItem(this.name, this.listArguments);
}
