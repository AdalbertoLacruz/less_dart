//source: less/tree/selector.js 3.5.0.beta.5 20180702

part of tree.less;

///
/// Selectors such as body, h1, ...
///
class Selector extends Node {
  @override final String type = 'Selector';

  ///
  Node            condition;
  ///  List<Element> elements; //body, ...
  List<Extend>    extendList;
  ///
  bool            evaldCondition = false;
  ///
  bool            mediaEmpty = false;
  /// Cached string elements List, such as ['#selector1', .., '.selectorN']
  List<String>    _mixinElements;

  ///
  /// elements is List<Element> | String (to be parsed)
  ///
  Selector(dynamic elements, {
      List<Extend> this.extendList,
      Node this.condition,
      int index,
      FileInfo currentFileInfo,
      VisibilityInfo visibilityInfo
      }) : super.init(currentFileInfo: currentFileInfo, index: index) {
    //clone if List.clear is used, because collateral effects
    this.elements = getElements(elements);
    evaldCondition = (condition == null);
    copyVisibilityInfo(visibilityInfo);
    setParent(this.elements, this);

//3.0.0 20170528
//  var Selector = function (elements, extendList, condition, index, currentFileInfo, visibilityInfo) {
//    this.extendList = extendList;
//    this.condition = condition;
//    this.evaldCondition = !condition;
//    this._index = index;
//    this._fileInfo = currentFileInfo;
//    this.elements = this.getElements(elements);
//    this.mixinElements_ = undefined;
//    this.copyVisibilityInfo(visibilityInfo);
//    this.setParent(this.elements, this);
//  };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'condition': condition,
    'elements': elements,
    'extendList': extendList
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (elements != null) elements = visitor.visitArray(elements);
    if (extendList != null) extendList = visitor.visitArray(extendList);
    if (condition != null) condition = visitor.visit(condition);

//2.3.1
//  Selector.prototype.accept = function (visitor) {
//      if (this.elements) {
//          this.elements = visitor.visitArray(this.elements);
//      }
//      if (this.extendList) {
//          this.extendList = visitor.visitArray(this.extendList);
//      }
//      if (this.condition) {
//          this.condition = visitor.visit(this.condition);
//      }
//  };
  }

  ///
  /// elements is List<Element> | String (to be parsed)
  ///
  Selector createDerived(dynamic elements,
      {List<Extend> extendList, bool evaldCondition}) =>
        new Selector(
          getElements(elements),
          extendList: extendList ?? this.extendList,
          condition: null,
          index: index,
          currentFileInfo: currentFileInfo,
          visibilityInfo: visibilityInfo())
            ..evaldCondition = evaldCondition ?? this.evaldCondition
            ..mediaEmpty = mediaEmpty;

//3.0.0 20170528
//  Selector.prototype.createDerived = function(elements, extendList, evaldCondition) {
//    elements = this.getElements(elements);
//    var newSelector = new Selector(elements, extendList || this.extendList,
//        null, this.getIndex(), this.fileInfo(), this.visibilityInfo());
//    newSelector.evaldCondition = (evaldCondition != null) ? evaldCondition : this.evaldCondition;
//    newSelector.mediaEmpty = this.mediaEmpty;
//    return newSelector;
//  };

  ///
  /// delayed parser for String elements, used in plugin api
  /// [els] is List<Element> | String
  ///
  List<Element> getElements(dynamic els) {
    if (els == null) return <Element>[new Element('', '&',
        isVariable: false, index: _index, currentFileInfo: _fileInfo)];

    if (els is String) {
      final Node result = new ParseNode(els, _index, _fileInfo).selector();
      if (result != null) return result.elements;
    }
    return els;

// 3.5.0.beta.5 20180702
//  Selector.prototype.getElements = function(els) {
//      if (!els) {
//          return [new Element('', '&', false, this._index, this._fileInfo)];
//      }
//      if (typeof els === 'string') {
//          this.parse.parseNode(
//              els,
//              ['selector'],
//              this._index,
//              this._fileInfo,
//              function(err, result) {
//                  if (err) {
//                      throw new LessError({
//                          index: err.index,
//                          message: err.message
//                      }, this.parse.imports, this._fileInfo.filename);
//                  }
//                  els = result[0].elements;
//              });
//      }
//      return els;
//  };
  }

  ///
  List<Selector> createEmptySelectors() {
    final Element el = new Element('', '&',
        isVariable: false,
        index: _index,
        currentFileInfo: _fileInfo);

    final List<Selector> sels = <Selector>[
      new Selector(<Element>[el],
        index: _index,
        currentFileInfo: _fileInfo)
    ];

    return sels
        ..first.mediaEmpty = true;

// 3.5.0.beta 20180625
//  Selector.prototype.createEmptySelectors = function() {
//      var el = new Element('', '&', false, this._index, this._fileInfo),
//          sels = [new Selector([el], null, null, this._index, this._fileInfo)];
//      sels[0].mediaEmpty = true;
//      return sels;
//  };
  }

  ///
  /// Compares this Selector with the [other] Selector
  ///
  /// Returns number of matched Selector elements if match. 0 means not match.
  ///
  int match(Selector other) {
    final List<String> otherElements = other.mixinElements();

    if (otherElements.isEmpty || elements.length < otherElements.length) {
      return 0;
    } else {
      for (int i = 0; i < otherElements.length; i++) {
        if (elements[i].value != otherElements[i]) return 0;
      }
    }
    return otherElements.length; // return number of matched elements

//3.0.0 20170528
// Selector.prototype.match = function (other) {
//     var elements = this.elements,
//         len = elements.length,
//         olen, i;
//
//     other = other.mixinElements();
//     olen = other.length;
//     if (olen === 0 || len < olen) {
//         return 0;
//     } else {
//         for (i = 0; i < olen; i++) {
//             if (elements[i].value !== other[i]) {
//                 return 0;
//             }
//         }
//     }
//
//     return olen; // return number of matched elements
// };
  }

  ///
  /// Creates _mixinElements as a String List of selector names
  ///
  /// Example: ['#sel1', '.sel2', ...]
  ///
  List<String> mixinElements() {
    final RegExp re = new RegExp(r'[,&#\*\.\w-]([\w-]|(\\.))*');

    if (_mixinElements != null) return _mixinElements; // cache exist

    final String css = elements
        .fold(new StringBuffer(), (StringBuffer prev, Element v) =>
          prev
              ..write(v.combinator.value)
              ..write((v.value is String)
                  ? v.value
                  : (v.value as Node).toCSS(null)))
        .toString();

    final Iterable<Match> matchs = re.allMatches(css);
    if (matchs != null) {
      _mixinElements = matchs.map((Match m) => m[0]).toList();
      if (_mixinElements.isNotEmpty && _mixinElements[0] == '&') {
        _mixinElements.removeAt(0);
      }
    } else {
      _mixinElements = <String>[];
    }

    return _mixinElements;

//3.0.0 20170528
// Selector.prototype.mixinElements = function() {
//     if (this.mixinElements_) {
//         return this.mixinElements_;
//     }
//
//     var elements = this.elements.map( function(v) {
//         return v.combinator.value + (v.value.value || v.value);
//     }).join("").match(/[,&#\*\.\w-]([\w-]|(\\.))*/g);
//
//     if (elements) {
//         if (elements[0] === "&") {
//             elements.shift();
//         }
//     } else {
//         elements = [];
//     }
//
//     return (this.mixinElements_ = elements);
// };
  }

  ///
  bool isJustParentSelector() =>
      !mediaEmpty &&
      elements.length == 1 &&
      elements[0].value == '&' &&
      (elements[0].combinator.value == ' ' ||
          elements[0].combinator.value == '');

  //2.3.1
//  Selector.prototype.isJustParentSelector = function() {
//      return !this.mediaEmpty &&
//          this.elements.length === 1 &&
//          this.elements[0].value === '&' &&
//          (this.elements[0].combinator.value === ' ' || this.elements[0].combinator.value === '');
//  };

  ///
  @override
  Selector eval(Contexts context) {
    final bool evaldCondition = condition?.eval(context)?.evaluated; //evaldCondition null is ok
    List<Element> elements = this.elements;
    List<Extend> extendList = this.extendList;

    if (elements != null) {
      elements = elements.map((Element e) => e.eval(context)).toList();
    }
    if (extendList != null) {
      extendList = extendList.map((Extend extend) => extend.eval(context)).toList();
    }

    return createDerived(elements,
        extendList: extendList,
        evaldCondition: evaldCondition);

//2.3.1
//  Selector.prototype.eval = function (context) {
//      var evaldCondition = this.condition && this.condition.eval(context),
//          elements = this.elements, extendList = this.extendList;
//
//      elements = elements && elements.map(function (e) { return e.eval(context); });
//      extendList = extendList && extendList.map(function(extend) { return extend.eval(context); });
//
//      return this.createDerived(elements, extendList, evaldCondition);
//  };
  }

  ///
  /// Writes Selector as String in [output]:
  ///  ' selector'. White space prefixed.
  ///
  @override
  void genCSS(Contexts context, Output output) {
    if ((context == null || !context.firstSelector) &&
        elements[0].combinator.value == '') {
      output.add(' ', fileInfo: currentFileInfo, index: index);
    }
    for (int i = 0; i < elements.length; i++) {
      elements[i].genCSS(context, output);
    }

//3.0.0 20170528
// Selector.prototype.genCSS = function (context, output) {
//     var i, element;
//     if ((!context || !context.firstSelector) && this.elements[0].combinator.value === "") {
//         output.add(' ', this.fileInfo(), this.getIndex());
//     }
//     for (i = 0; i < this.elements.length; i++) {
//         element = this.elements[i];
//         element.genCSS(context, output);
//     }
// };
  }

  ///
  bool getIsOutput() => evaldCondition;

//2.3.1
//  Selector.prototype.getIsOutput = function() {
//      return this.evaldCondition;
//  };

  @override
  String toString() {
    final Output output = new Output();
    elements.forEach((Node e) {
      e.genCSS(null, output);
    });
    return output.toString().trim();
  }
}
