//source: less/tree/extend.js 2.5.3 20151120

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
  Extend(Node this.selector, String this.option, int this.index,
      FileInfo currentFileInfo, [VisibilityInfo visibilityInfo]) {
    //
    objectId = nextId++;
    parentIds = <int>[objectId];
    this.currentFileInfo = currentFileInfo ?? new FileInfo();
    copyVisibilityInfo(visibilityInfo);

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

//2.5.3 20151120
// var Extend = function Extend(selector, option, index, currentFileInfo, visibilityInfo) {
//     this.selector = selector;
//     this.option = option;
//     this.index = index;
//     this.object_id = Extend.next_id++;
//     this.parent_ids = [this.object_id];
//     this.currentFileInfo = currentFileInfo || {};
//     this.copyVisibilityInfo(visibilityInfo);
//
//     switch(option) {
//         case "all":
//             this.allowBefore = true;
//             this.allowAfter = true;
//             break;
//         default:
//             this.allowBefore = false;
//             this.allowAfter = false;
//             break;
//     }
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'selector': selector,
    'option': option
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    selector = visitor.visit(selector);

//2.3.1
//  Extend.prototype.accept = function (visitor) {
//      this.selector = visitor.visit(this.selector);
//  };
  }

  ///
  @override
  Extend eval(Contexts context) =>
      new Extend(selector.eval(context), option, index, currentFileInfo, visibilityInfo());

//2.5.3 20151120
// Extend.prototype.eval = function (context) {
//     return new Extend(this.selector.eval(context), this.option, this.index, this.currentFileInfo, this.visibilityInfo());
// };

  ///
  //removed clone(context)
  Node clone() =>
      new Extend(selector, option, index, currentFileInfo, visibilityInfo());

//2.5.3 20151120
// Extend.prototype.clone = function (context) {
//     return new Extend(this.selector, this.option, this.index, this.currentFileInfo, this.visibilityInfo());
// };

  ///
  /// It concatenates (joins) all selectors in selector array
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
    selfSelectors[0].copyVisibilityInfo(visibilityInfo());

//2.5.3 20151120
//it concatenates (joins) all selectors in selector array
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
//      this.selfSelectors = [new Selector(selfElements)];
//      this.selfSelectors[0].copyVisibilityInfo(this.visibilityInfo());
//  };
  }

  @override
  String toString() {
    final Output output = new Output();
    selector.genCSS(null, output);
    if(option != null)
        output.add(' $option');
    return output.toString().trim();
  }
}
