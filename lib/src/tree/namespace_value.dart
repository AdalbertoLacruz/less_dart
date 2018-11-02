// source: less/tree/namespace-value.js 3.5.0.beta.4 20180630

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
  /// Ex.
  ///   color: #color[primary]
  ///   
  NamespaceValue(Node ruleCall, List<String> this.lookups,
      { int index, FileInfo fileInfo, bool this.important })
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

      // Eval'd mixins return rules
      if (rules is Nodeset) {
        final List<Node> nsRules = rules.rules;
        name = name.startsWith(r'$') ? name.substring(1) : name;

        // Find the last declaration match
        bool found = false;
        for (int j = nsRules.length - 1; j >= 0; j--) {
          if (nsRules[j].name == name) {
            found = true;
            rules = nsRules[j];
            break;
          }
        }

        if (!found) {
          final String message = name.startsWith('@')
            ? 'variable $name not found'
            : 'property "$name" not found';

          throw new LessExceptionError(new LessError(
            type: 'Name',
            message: message,
            filename: currentFileInfo.filename,
            index: index
          ));
        }
      } else { // Eval'd DRs return rulesets
        if (name.startsWith('@')) {
          if (name.startsWith('@@')) {
            // ignore: prefer_interpolation_to_compose_strings
            name = '@' + new Variable(name.substring(1)).eval(context).value;
          }
          if (rules is VariableMixin) {
            rules = (rules as VariableMixin).variables()[name];
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
          if (rules is VariableMixin) {
            lsRules = rules.properties()[name.startsWith(r'$') ? name : '\$$name'];
          }
          if (lsRules == null) {
            throw new LessExceptionError(new LessError(
                type: 'Name',
                message: 'property "$name" not found',
                filename: currentFileInfo.filename,
                index: index
            ));
          }
          // Properties are an array of values, since a ruleset can have multiple props.
          // We pick the last one (the "cascaded" value)
          rules = lsRules.last;
        }
      }
      if (rules.value != null) rules = rules.eval(context).value;
      if (rules is DetachedRuleset) {
        rules = (rules as DetachedRuleset).ruleset.eval(context);
      }
    }

    return rules;

// 3.5.0.beta.4 20180630
//  NamespaceValue.prototype.eval = function (context) {
//      var i, j, name, found,
//          rules = this.value.eval(context);
//
//      for (i = 0; i < this.lookups.length; i++) {
//          name = this.lookups[i];
//
//          // Eval'd mixins return rules
//          if (Array.isArray(rules)) {
//              name = name.charAt(0) === '$' ? name.substr(1) : name;
//              // Find the last declaration match
//              for (j = rules.length - 1; j >= 0; j--) {
//                  if (rules[j].name === name) {
//                      found = true;
//                      rules = rules[j];
//                      break;
//                  }
//              }
//              if (!found) {
//                  var message = name.charAt(0) === '@' ?
//                      'variable ' + name + ' not found' :
//                      'property "' + name + ' not found';
//
//                  throw { type: 'Name',
//                      message: message,
//                      filename: this.fileInfo().filename,
//                      index: this.getIndex() };
//              }
//          }
//          // Eval'd DRs return rulesets
//          else {
//              if (name.charAt(0) === '@') {
//                  if (name.charAt(1) === '@') {
//                      name = '@' + new Variable(name.substr(1)).eval(context).value;
//                  }
//                  if (rules.variables) {
//                      rules = rules.variables()[name];
//                  }
//
//                  if (!rules) {
//                      throw { type: 'Name',
//                          message: 'variable ' + name + ' not found',
//                          filename: this.fileInfo().filename,
//                          index: this.getIndex() };
//                  }
//              }
//              else {
//                  if (rules.properties) {
//                      rules = rules.properties()[name.charAt(0) === '$' ? name : '$' + name];
//                  }
//
//                  if (!rules) {
//                      throw { type: 'Name',
//                          message: 'property "' + name + '" not found',
//                          filename: this.fileInfo().filename,
//                          index: this.getIndex() };
//                  }
//                  // Properties are an array of values, since a ruleset can have multiple props.
//                  // We pick the last one (the "cascaded" value)
//                  rules = rules[rules.length - 1];
//              }
//          }
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
