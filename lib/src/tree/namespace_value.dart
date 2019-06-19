// source: less/tree/namespace-value.js 3.5.0.beta.6 20180704

part of tree.less;

///
class NamespaceValue extends Node {
  @override final String    type = 'NamespaceValue';

  @override covariant Node   value;

  ///
  bool      important;

  ///
  List<String> lookups;

  ///
  /// Store Namespaces Values
  // Ex.
  //   color: #color[primary]
  ///   
  NamespaceValue(Node ruleCall, this.lookups,
      { int index, FileInfo fileInfo, this.important })
      : super.init(currentFileInfo: fileInfo, index: index) {
    // ignore: prefer_initializing_formals
    value = ruleCall;

// 3.5.0.beta.4 20180630
//  var NamespaceValue = function (ruleCall, lookups, important, index, fileInfo) {
//      this.value = ruleCall;
//      this.lookups = lookups;
//      this.important = important;
//      this._index = index;
//      this._fileInfo = fileInfo;
//  };
  }

  ///
  @override
  Node eval(Contexts context) {
    Node rules = value.eval(context);

    for (int i = 0; i < lookups.length; i++) {
      String name = lookups[i];

      // Eval'd DRs return rulesets.
      // Eval'd mixins return rules, so let's make a ruleset if we need it.
      // We need to do this because of late parsing of values
      if (rules is Nodeset) {
        rules = new Ruleset(<Selector>[new Selector(null)], rules.rules);
      }

      if (name.isEmpty && rules is VariableMixin) {
        rules = (rules as VariableMixin).lastDeclaration();
      } else if (name.startsWith('@')) {
        if (name.startsWith('@@')) {
          // ignore: prefer_interpolation_to_compose_strings
          name = '@' + new Variable(name.substring(1)).eval(context).value;
        }
        if (rules is VariableMixin) {
          rules = (rules as VariableMixin).variable(name);
        }
        if (rules == null) {
          throw new LessExceptionError(new LessError(
              type: 'Name',
              message: 'variable $name not found',
              filename: currentFileInfo.filename,
              index: index
          ));
        }
      } else {
        List<Node> lsRules;
        if (name.startsWith(r'$@')) {
          // ignore: prefer_interpolation_to_compose_strings
          name = r'$' + new Variable(name.substring(1)).eval(context).value;
        } else {
          name = name.startsWith(r'$') ? name : '\$$name';
        }

        if (rules is VariableMixin) {
          lsRules = rules.property(name);
        }

        if (lsRules == null) {
          throw new LessExceptionError(new LessError(
              type: 'Name',
              message: 'property "${name.substring(1)}" not found',
              filename: currentFileInfo.filename,
              index: index
          ));
        }
        // Properties are an array of values, since a ruleset can have multiple props.
        // We pick the last one (the "cascaded" value)
        rules = lsRules.last;
      }
      if (rules.value != null) rules = rules.eval(context).value;
      if (rules is DetachedRuleset) {
        rules = (rules as DetachedRuleset).ruleset.eval(context);
      }
    }

    return rules;

// 3.5.0.beta.6 20180704
//  NamespaceValue.prototype.eval = function (context) {
//      var i, j, name, rules = this.value.eval(context);
//
//      for (i = 0; i < this.lookups.length; i++) {
//          name = this.lookups[i];
//
//          /**
//           * Eval'd DRs return rulesets.
//           * Eval'd mixins return rules, so let's make a ruleset if we need it.
//           * We need to do this because of late parsing of values
//           */
//          if (Array.isArray(rules)) {
//              rules = new Ruleset([new Selector()], rules);
//          }
//
//          if (name === '') {
//              rules = rules.lastDeclaration();
//          }
//          else if (name.charAt(0) === '@') {
//              if (name.charAt(1) === '@') {
//                  name = '@' + new Variable(name.substr(1)).eval(context).value;
//              }
//              if (rules.variables) {
//                  rules = rules.variable(name);
//              }
//
//              if (!rules) {
//                  throw { type: 'Name',
//                      message: 'variable ' + name + ' not found',
//                      filename: this.fileInfo().filename,
//                      index: this.getIndex() };
//              }
//          }
//          else {
//              if (name.substring(0, 2) === '$@') {
//                  name = '$' + new Variable(name.substr(1)).eval(context).value;
//              }
//              else {
//                  name = name.charAt(0) === '$' ? name : '$' + name;
//              }
//              if (rules.properties) {
//                  rules = rules.property(name);
//              }
//
//              if (!rules) {
//                  throw { type: 'Name',
//                      message: 'property "' + name.substr(1) + '" not found',
//                      filename: this.fileInfo().filename,
//                      index: this.getIndex() };
//              }
//              // Properties are an array of values, since a ruleset can have multiple props.
//              // We pick the last one (the "cascaded" value)
//              rules = rules[rules.length - 1];
//          }
//
//          if (rules.value) {
//              rules = rules.eval(context).value;
//          }
//          if (rules.ruleset) {
//              rules = rules.ruleset.eval(context);
//          }
//      }
//      return rules;
//  };
  }
}
