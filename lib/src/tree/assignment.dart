//source: less/tree/assignment.js 2.5.0

part of tree.less;

///
/// Assignments are argument entities for calls.
/// They are present in ie filter properties as shown below.
///
///     filter: progid:DXImageTransform.Microsoft.Alpha( *opacity=50* )
///
class Assignment extends Node {
  @override
  final String name = null;

  @override
  final String type = 'Assignment';

  ///
  String key;

  /// value == Node | String
  Assignment(this.key, dynamic value) : super.init(value: value);

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'key': key, 'value': value};

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    value = visitor.visit(value);

//2.3.1
//  Assignment.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  @override
  Assignment eval(Contexts context) =>
      (value is Node) ? Assignment(key, value.eval(context)) : this;

//2.3.1
//  Assignment.prototype.eval = function (context) {
//      if (this.value.eval) {
//          return new Assignment(this.key, this.value.eval(context));
//      }
//      return this;
//  };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('$key=');
    (value is Node) ? value.genCSS(context, output) : output.add(value);

//2.3.1
//  Assignment.prototype.genCSS = function (context, output) {
//      output.add(this.key + '=');
//      if (this.value.genCSS) {
//          this.value.genCSS(context, output);
//      } else {
//          output.add(this.value);
//      }
//  };
  }

  @override
  String toString() {
    final Output output = Output();
    genCSS(null, output);
    return output.toString();
  }
}
