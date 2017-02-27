part of tree.less;

///
/// When a method returns List<Node> instead Node as required by the interface,
/// Nodeset let encapsulate the List and return Node, as Nodeset.rules
///
class Nodeset extends Node {

  final String type = 'Nodeset';

  Nodeset(List<Node> rules) {
    this.rules = rules;
  }

  ///
  /// Control test. Nodeset must be destroyed before this point
  /// 
  void genCSS(Contexts context, Output output) {
    output.add('/* Nodeset error */');
  }
}
