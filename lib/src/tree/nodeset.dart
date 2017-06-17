part of tree.less;

///
/// When a method returns List<Node> instead Node as required by the interface,
/// Nodeset let encapsulate the List and return Node, as Nodeset.rules
///
class Nodeset extends Node {
  @override final String type = 'Nodeset';

  Nodeset(List<Node> rules) : super.init(rules: rules);

  ///
  /// Control test. Nodeset must be destroyed before this point
  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('/* Nodeset error */');
  }
}
