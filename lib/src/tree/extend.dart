//source: less/tree/extend.js 1.7.5

part of tree.less;

class Extend extends Node implements EvalNode {
  Node selector;
  String option;
  int index;

  bool            allowAfter;
  bool            allowBefore;
  bool            firstExtendOnThisSelectorPath = false;
  int             object_id;
  List<int>       parent_ids;
  Ruleset         ruleset; //extend
  List<Selector>  selfSelectors;

  static int next_id = 0; //TODO review with multi-thread

  final String type = 'Extend';

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
  }

  ///
  void accept(Visitor visitor) {
    this.selector = visitor.visit(this.selector);
  }

  ///
  Extend eval(Contexts env) => new Extend(this.selector.eval(env), this.option, this.index);

  ///
  Node clone() => new Extend (this.selector, this.option, this.index);

//      clone: function (env) {// removed env
//          return new(tree.Extend)(this.selector, this.option, this.index);
//      },

  void findSelfSelectors(List<Selector> selectors) {
    List selfElements = [];
    List<Element> selectorElements;

    for (int i = 0; i < selectors.length; i++) {
      selectorElements = selectors[i].elements;

      // duplicate the logic in genCSS function inside the selector node.
      // future TODO - move both logics into the selector joiner visitor
      if (i > 0 && selectorElements.isNotEmpty && selectorElements.first.combinator.value.isEmpty) {
        selectorElements.first.combinator.value = ' ';
      }
      selfElements.addAll(selectors[i].elements);
    }

    this.selfSelectors = [new Selector(selfElements)];

//      findSelfSelectors: function (selectors) {
//          var selfElements = [],
//              i,
//              selectorElements;
//
//          for(i = 0; i < selectors.length; i++) {
//              selectorElements = selectors[i].elements;
//              // duplicate the logic in genCSS function inside the selector node.
//              // future TODO - move both logics into the selector joiner visitor
//              if (i > 0 && selectorElements.length && selectorElements[0].combinator.value === "") {
//                  selectorElements[0].combinator.value = ' ';
//              }
//              selfElements = selfElements.concat(selectors[i].elements);
//          }
//
//          this.selfSelectors = [{ elements: selfElements }];

//      }
  }
}