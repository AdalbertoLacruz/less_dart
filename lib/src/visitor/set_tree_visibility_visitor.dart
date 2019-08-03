// source: set-tree-visibility-visitor.js 2.5.3 20151120

part of visitor.less;

///
class SetTreeVisibilityVisitor extends VisitorBase {
  ///
  bool visible;

  ///
  SetTreeVisibilityVisitor({this.visible});

//2.5.3 20151120
// var SetTreeVisibilityVisitor = function(visible) {
//     this.visible = visible;
// };

  ///
  @override
  Ruleset run(Ruleset root) {
    visit(root);
    return null;

//2.5.3 20151120
// SetTreeVisibilityVisitor.prototype.run = function(root) {
//     this.visit(root);
// };
  }

  ///
  @override
  List<T> visitArray<T>(List<T> nodes, {bool nonReplacing = false}) {
    if (nodes == null) return nodes;
    return nodes..forEach(visit);

//2.5.3 20151120
// SetTreeVisibilityVisitor.prototype.visitArray = function(nodes) {
//     if (!nodes) {
//         return nodes;
//     }
//
//     var cnt = nodes.length, i;
//     for (i = 0; i < cnt; i++) {
//         this.visit(nodes[i]);
//     }
//     return nodes;
// };
  }

  ///
  @override
  dynamic visit(dynamic node) {
    if (node == null) return node;
    if (node is List) return visitArray(node);
    if (node is! Node) return node;

    final Node _node = node;
    if (_node.blocksVisibility()) return _node;

    visible ? _node.ensureVisibility() : _node.ensureInvisibility();
    _node.accept(this);
    return _node;

//2.5.3 20151120
// SetTreeVisibilityVisitor.prototype.visit = function(node) {
//     if (!node) {
//         return node;
//     }
//     if (node.constructor === Array) {
//         return this.visitArray(node);
//     }
//
//     if (!node.blocksVisibility || node.blocksVisibility()) {
//         return node;
//     }
//     if (this.visible) {
//         node.ensureVisibility();
//     } else {
//         node.ensureInvisibility();
//     }
//
//     node.accept(this);
//     return node;
// };
  }
}
