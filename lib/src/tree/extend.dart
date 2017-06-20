//source: less/tree/extend.js 2.5.0

part of tree.less;

///
class Extend extends Node {
  @override final String name = null;
  @override final String type = 'Extend';

  ///
  bool            allowAfter;
  ///
  bool            allowBefore;
  ///
  bool            firstExtendOnThisSelectorPath = false;
  ///
  bool            hasFoundMatches = false; // ProcessExtendsVisitor
  ///
  int             index;
  ///
  static int      nextId = 0;
  ///
  int             objectId;
  ///
  String          option;
  ///
  List<int>       parentIds;
  ///
  Ruleset         ruleset; //extend
  ///
  Node            selector;
  ///
  List<Selector>  selfSelectors;

  ///
  Extend(Node this.selector, String this.option, int this.index) {
    objectId = nextId++;
    parentIds = <int>[objectId];

    switch (option) {
      case 'all':
        allowBefore = true;
        allowAfter = true;
        break;
      default:
        allowBefore = false;
        allowAfter = false;
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
  @override
  void accept(covariant Visitor visitor) {
    selector = visitor.visit(selector);

//2.3.1
//  Extend.prototype.accept = function (visitor) {
//      this.selector = visitor.visit(this.selector);
//  };
  }

  ///
  @override
  Extend eval(Contexts context) =>
      new Extend(selector.eval(context), option, index);

//2.3.1
//  Extend.prototype.eval = function (context) {
//      return new Extend(this.selector.eval(context), this.option, this.index);
//  };

  ///
  //removed clone(context)
  Node clone() => new Extend(selector, option, index);

//2.3.1
//  Extend.prototype.clone = function (context) {
//      return new Extend(this.selector, this.option, this.index);
//  };

  ///
  void findSelfSelectors(List<Selector> selectors) {
    List<Element>       selectorElements;
    final List<Element> selfElements = <Element>[];

    for (int i = 0; i < selectors.length; i++) {
      selectorElements = selectors[i].elements;

      // duplicate the logic in genCSS function inside the selector node.
      // future todo (js) - move both logics into the selector joiner visitor
      if (i > 0 &&
          selectorElements.isNotEmpty &&
          selectorElements.first.combinator.value.isEmpty) {
        selectorElements.first.combinator.value = ' ';
      }
      selfElements.addAll(selectors[i].elements);
    }

    selfSelectors = <Selector>[new Selector(selfElements)];

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
