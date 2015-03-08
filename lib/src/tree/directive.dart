//source: less/tree/directive.js 2.4.0

part of tree.less;

class Directive extends Node with OutputRulesetMixin, VariableMixin implements GetIsReferencedNode, MarkReferencedNode {
  String name;
  Node value;
  var rules; //Ruleset
  int index;
  FileInfo currentFileInfo;
  DebugInfo debugInfo;
  bool isReferenced;

  final String type = 'Directive';

  ///
  //2.3.1 ok
  Directive(String this.name, Node this.value,  this.rules, int this.index,
      FileInfo this.currentFileInfo, DebugInfo this.debugInfo, [bool this.isReferenced = false]) {
    if (this.rules != null) this.rules.allowImports = true;
  }

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
//    Node value = this.value;
//    Ruleset rules = this.rules;

    if (this.rules != null) this.rules = visitor.visit(this.rules);
    if (this.value != null) this.value = visitor.visit(this.value);

//2.3.1
//  Directive.prototype.accept = function (visitor) {
//      var value = this.value, rules = this.rules;
//      if (rules) {
//          this.rules = visitor.visit(rules);
//      }
//      if (value) {
//          this.value = visitor.visit(value);
//      }
//  };
  }

  ///
  //2.3.1 ok
  bool isRulesetLike(bool root)  => (this.rules != null) || !this.isCharset();

//2.3.1
//  Directive.prototype.isRulesetLike = function() {
//      return this.rules || !this.isCharset();
//  };

  ///
  //2.3.1 ok
  bool isCharset() => '@charset' == this.name;

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    Node value = this.value;
    var rules = this.rules;
    output.add(this.name, this.currentFileInfo, this.index);
    if (value != null) {
      output.add(' ');
      value.genCSS(context, output);
    }
    if (rules != null) {
      if (rules is Ruleset) rules = [rules];
      outputRuleset(context, output, rules);
    } else {
      output.add(';');
    }

//2.3.1
//  Directive.prototype.genCSS = function (context, output) {
//      var value = this.value, rules = this.rules;
//      output.add(this.name, this.currentFileInfo, this.index);
//      if (value) {
//          output.add(' ');
//          value.genCSS(context, output);
//      }
//      if (rules) {
//          if (rules.type === "Ruleset") {
//              rules = [rules];
//          }
//          this.outputRuleset(context, output, rules);
//      } else {
//          output.add(';');
//      }
//  };
  }

//    toCSS: tree.toCSS,

  ///
  //2.3.1 ok
  Directive eval(Contexts context) {
    Node value = this.value;
    Ruleset rules = this.rules;

    if (value != null) value = value.eval(context);
    if (rules != null) {
      rules = rules.eval(context);
      rules.root = true;
    }
    return new Directive(this.name, value, rules,
        this.index, this.currentFileInfo, this.debugInfo, this.isReferenced);

//2.3.1
//  Directive.prototype.eval = function (context) {
//      var value = this.value, rules = this.rules;
//      if (value) {
//          value = value.eval(context);
//      }
//      if (rules) {
//          rules = rules.eval(context);
//          rules.root = true;
//      }
//      return new Directive(this.name, value, rules,
//          this.index, this.currentFileInfo, this.debugInfo, this.isReferenced);
//  };
  }

// in VariableMixin
//2.3.1
//  Directive.prototype.variable = function (name) {
//      if (this.rules) {
//          return Ruleset.prototype.variable.call(this.rules, name);
//      }
//  };
//  Directive.prototype.find = function () {
//      if (this.rules) {
//          return Ruleset.prototype.find.apply(this.rules, arguments);
//      }
//  };
//  Directive.prototype.rulesets = function () {
//      if (this.rules) {
//          return Ruleset.prototype.rulesets.apply(this.rules);
//      }
//  };

  //--- MarkReferencedNode

  ///
  //2.3.1 ok
  void markReferenced() {
    List<Node> rules;
    this.isReferenced = true;

    if (this.rules != null) {
      rules = this.rules.rules;
      for (int i = 0; i < rules.length; i++) {
        if (rules[i] is MarkReferencedNode) (rules[i] as MarkReferencedNode).markReferenced();
      }
    }

//2.3.1
//  Directive.prototype.markReferenced = function () {
//      var i, rules;
//      this.isReferenced = true;
//      if (this.rules) {
//          rules = this.rules.rules;
//          for (i = 0; i < rules.length; i++) {
//              if (rules[i].markReferenced) {
//                  rules[i].markReferenced();
//              }
//          }
//      }
//  };
  }

  ///
  //2.3.1 ok
  bool getIsReferenced() => (this.currentFileInfo == null)
                          || !this.currentFileInfo.reference
                          || this.isReferenced;

//2.3.1
//  Directive.prototype.getIsReferenced = function () {
//      return !this.currentFileInfo || !this.currentFileInfo.reference || this.isReferenced;
//  };
}