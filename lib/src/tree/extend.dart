//source: less/tree/extend.js 2.3.1

part of tree.less;

class Extend extends Node {
  Node selector;
  String option;
  int index;

  bool            allowAfter;
  bool            allowBefore;
  bool            firstExtendOnThisSelectorPath = false;
  bool            hasFoundMatches = false; // ProcessExtendsVisitor
  int             object_id;
  List<int>       parent_ids;
  Ruleset         ruleset; //extend
  List<Selector>  selfSelectors;

  static int next_id = 0;

  final String type = 'Extend';

  ///
  //2.3.1 ok
  Extend(Node this.selector, String this.option, int this.index) {
    this.object_id = next_id++;
    this.parent_ids = [this.object_id];

    switch(option) {
      case 'all':
        this.allowBefore = true;
        this.allowAfter = true;
        break;
      default:
        this.allowBefore = false;
        this.allowAfter = false;
        break;
    }

//2.3.1
//  var Extend = function Extend(selector, option, index) {
//      this.selector = selector;
//      this.option = option;
//      this.index = index;
//      this.object_id = Extend.next_id++;
//      this.parent_ids = [this.object_id];
//
//      switch(option) {
//          case "all":
//              this.allowBefore = true;
//              this.allowAfter = true;
//          break;
//          default:
//              this.allowBefore = false;
//              this.allowAfter = false;
//          break;
//      }
//  };
  }

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    this.selector = visitor.visit(this.selector);

//2.3.1
//  Extend.prototype.accept = function (visitor) {
//      this.selector = visitor.visit(this.selector);
//  };
  }

  ///
  //2.3.1 ok
  Extend eval(Contexts context) => new Extend(this.selector.eval(context), this.option, this.index);

//2.3.1
//  Extend.prototype.eval = function (context) {
//      return new Extend(this.selector.eval(context), this.option, this.index);
//  };

  ///
  //2.3.1 ok - // removed clone(context)
  Node clone() => new Extend (this.selector, this.option, this.index);

//2.3.1
//  Extend.prototype.clone = function (context) {
//      return new Extend(this.selector, this.option, this.index);
//  };

  ///
  //2.3.1 ok
  void findSelfSelectors(List<Selector> selectors) {
    List selfElements = [];
    List<Element> selectorElements;

    for (int i = 0; i < selectors.length; i++) {
      selectorElements = selectors[i].elements;

      // duplicate the logic in genCSS function inside the selector node.
      // future todo (js) - move both logics into the selector joiner visitor
      if (i > 0 && selectorElements.isNotEmpty && selectorElements.first.combinator.value.isEmpty) {
        selectorElements.first.combinator.value = ' ';
      }
      selfElements.addAll(selectors[i].elements);
    }

    this.selfSelectors = [new Selector(selfElements)];

//2.3.1
//  Extend.prototype.findSelfSelectors = function (selectors) {
//      var selfElements = [],
//          i,
//          selectorElements;
//
//      for(i = 0; i < selectors.length; i++) {
//          selectorElements = selectors[i].elements;
//          // duplicate the logic in genCSS function inside the selector node.
//          // future todo - move both logics into the selector joiner visitor
//          if (i > 0 && selectorElements.length && selectorElements[0].combinator.value === "") {
//              selectorElements[0].combinator.value = ' ';
//          }
//          selfElements = selfElements.concat(selectors[i].elements);
//      }
//
//      this.selfSelectors = [{ elements: selfElements }];
//  };
  }
}