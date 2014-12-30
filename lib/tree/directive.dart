//source: less/tree/directive.js 1.7.5

part of tree.less;

class Directive extends Node with OutputRulesetMixin, VariableMixin implements EvalNode, MarkReferencedNode, ToCSSNode {
  String name;
  Node value;
  var rules; //Ruleset
  int index;
  FileInfo currentFileInfo;
  LessDebugInfo debugInfo;

  bool isReferenced = false;

  final String type = 'Directive';

  Directive(String this.name, Node this.value,  this.rules, int this.index, FileInfo this.currentFileInfo, LessDebugInfo this.debugInfo) {
    if (this.rules != null) this.rules.allowImports = true;
  }

  ///
  void accept(Visitor visitor) {
    Node value = this.value;
    Ruleset rules = this.rules;

    if (rules != null) rules = visitor.visit(rules);
    if (value != null) value = visitor.visit(value);
  }

  ///
  bool isRulesetLike()  => !this.isCharset();

  ///
  bool isCharset() => '@charset' == this.name;

  ///
  void genCSS(Env env, Output output) {
    Node value = this.value;
    Node rules = this.rules;
    output.addFull(this.name, this.currentFileInfo, this.index);
    if (value != null) {
      output.add(' ');
      value.genCSS(env, output);
    }
    if (rules != null) {
      outputRuleset(env, output, [rules]);
    } else {
      output.add(';');
    }

//    genCSS: function (env, output) {
//        var value = this.value, rules = this.rules;
//        output.add(this.name, this.currentFileInfo, this.index);
//        if (value) {
//            output.add(' ');
//            value.genCSS(env, output);
//        }
//        if (rules) {
//            tree.outputRuleset(env, output, [rules]);
//        } else {
//            output.add(';');
//        }
//    },
  }

//    toCSS: tree.toCSS,

  ///
  Directive eval(Env env) {
    Node value = this.value;
    Ruleset rules = this.rules;

    if (value != null) value = value.eval(env);
    if (rules != null) {
      rules = rules.eval(env);
      rules.root = true;
    }
    return new Directive(this.name, value, rules,
        this.index, this.currentFileInfo, this.debugInfo);
  }

// in VariableMixin
//  variable(name) {
////    variable: function (name) { if (this.rules) return tree.Ruleset.prototype.variable.call(this.rules, name); },
//  }
//
//  find() {
////    find: function () { if (this.rules) return tree.Ruleset.prototype.find.apply(this.rules, arguments); },
//  }
//
//  rulesets() {
////    rulesets: function () { if (this.rules) return tree.Ruleset.prototype.rulesets.apply(this.rules); },
//  }


  //--- MarkReferencedNode

  ///
  void markReferenced() {
    List<Node> rules;
    this.isReferenced = true;

    if (this.rules != null) {
      rules = this.rules.rules;
      for (int i = 0; i < rules.length; i++) {
        if (rules[i] is MarkReferencedNode) (rules[i] as MarkReferencedNode).markReferenced();
      }
    }

//    markReferenced: function () {
//        var i, rules;
//        this.isReferenced = true;
//        if (this.rules) {
//            rules = this.rules.rules;
//            for (i = 0; i < rules.length; i++) {
//                if (rules[i].markReferenced) {
//                    rules[i].markReferenced();
//                }
//            }
//        }
//    }
  }
}