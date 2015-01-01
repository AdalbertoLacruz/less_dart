//source: less/tree/selector.js 1.7.5

part of tree.less;

// Selectors such as body, h1, ...
class Selector extends Node implements EvalNode, MarkReferencedNode, ToCSSNode {
  List<Element> elements; //body, ...
  List<Node> extendList;
  Node condition;
  int index;
  FileInfo currentFileInfo;
  bool isReferenced = false;

  String _css;

  /// Cached string elements List, such as ['#selector1', .., '.selectorN']
  List<String> _elements;

  bool evaldCondition = false;
  bool mediaEmpty = false;

  /// String Elements List
  List<String> get strElements {
    if (_elements == null) cacheElements();
    return _elements;
  }

  final String type = 'Selector';

  Selector (List<Node> this.elements, [List<Node> this.extendList, Node this.condition, int this.index,
                            FileInfo this.currentFileInfo, bool this.isReferenced]) {
    if (this.currentFileInfo == null) this.currentFileInfo = new FileInfo();
    if (this.condition == null) this.evaldCondition = true;
  }

  ///
  void accept(Visitor visitor) {
    if (this.elements != null) this.elements = visitor.visitArray(this.elements);
    if (this.extendList != null) this.extendList = visitor.visitArray(this.extendList);
    if (this.condition != null) this.condition = visitor.visit(this.condition);
  }

  ///
  Selector createDerived(List<Element> elements, [List<Node> extendList, bool evaldCondition]) {
    evaldCondition = (evaldCondition != null)? evaldCondition : this.evaldCondition;

    Selector newSelector = new Selector(elements, extendList != null ? extendList : this.extendList, null,
        this.index, this.currentFileInfo, this.isReferenced)
        ..evaldCondition = evaldCondition
        ..mediaEmpty = this.mediaEmpty;
    return newSelector;

//    createDerived: function(elements, extendList, evaldCondition) {
//        evaldCondition = (evaldCondition != null) ? evaldCondition : this.evaldCondition;
//        var newSelector = new(tree.Selector)(elements, extendList || this.extendList, null, this.index,
//                          this.currentFileInfo, this.isReferenced);
//        newSelector.evaldCondition = evaldCondition;
//        newSelector.mediaEmpty = this.mediaEmpty;
//        return newSelector;
//    },
  }

  ///
  /// Compares this Selector with the [other] Selector
  ///
  /// Returns number of matched Selector elements if match. 0 means not match.
  /// #
  int match(Selector other) {
    List<String> thisStrElements = this.strElements;
    List<String> otherStrElements = other.strElements;

    if (otherStrElements.isEmpty || thisStrElements.length < otherStrElements.length) {
      return 0;
    } else {
      for (int i = 0; i < otherStrElements.length; i++) {
        if (thisStrElements[i] != otherStrElements[i]) return 0;
      }
    }
    return otherStrElements.length;

// -- VALID IMPLEMENTATION --
//    List<Element> elements = this.elements;
//    int len = elements.length;
//    int olen; //other elements.length
//
//    other.cacheElements(); //Create if not, other._elements
//
//    olen = other._elements.length;
//    if (olen == 0 || len < olen) {
//      return 0;
//    } else {
//      for (int i = 0; i < olen; i++) {
//        if (elements[i].value != other._elements[i]) return 0;
//      }
//    }
//
//    return olen;


//    match: function (other) {
//        var elements = this.elements,
//            len = elements.length,
//            olen, i;
//
//        other.CacheElements();
//
//        olen = other._elements.length;
//        if (olen === 0 || len < olen) {
//            return 0;
//        } else {
//            for (i = 0; i < olen; i++) {
//                if (elements[i].value !== other._elements[i]) {
//                    return 0;
//                }
//            }
//        }
//
//        return olen; // return number of matched elements
//    },
  }

  ///
  /// Creates this._elements as a String List of selector names
  ///
  /// Example: ['#sel1', '.sel2', ...]
  /// #
  void cacheElements() {
    String css = '';
    int len;
    Element v;
    RegExp re = new RegExp(r'[,&#\*\.\w-]([\w-]|(\\.))*');

    if (this._elements == null) {
      len = this.elements.length;
      for (int i = 0; i < len; i++) {
        v = this.elements[i];
        css += v.combinator.value;

        if (v.value is String) { //String or Node
          css += v.value;
          continue;
        }

        if (v.value.value is! String) {
          css = '';
          break;
        }
        css += v.value.value;
      }

      Iterable<Match> matchs = re.allMatches(css);
      if (matchs != null) {
        this._elements = matchs.map((m) => m[0]).toList();
        if (this._elements.isNotEmpty && this._elements[0] == '&') this._elements.removeAt(0);
      } else {
        this._elements = [];
      }
    }

//    CacheElements: function(){
//        var css = '', len, v, i;
//
//        if( !this._elements ){
//
//            len = this.elements.length;
//            for(i = 0; i < len; i++){
//
//                v = this.elements[i];
//                css += v.combinator.value;
//
//                if( !v.value.value ){
//                    css += v.value;
//                    continue;
//                }
//
//                if( typeof v.value.value !== "string" ){
//                    css = '';
//                    break;
//                }
//                css += v.value.value;
//            }
//
//            this._elements = css.match(/[,&#\*\.\w-]([\w-]|(\\.))*/g);
//
//            if (this._elements) {
//                if (this._elements[0] === "&") {
//                    this._elements.shift();
//                }
//
//            } else {
//                this._elements = [];
//            }
//
//        }
//    },
  }

  /// #
  bool isJustParentSelector() => !this.mediaEmpty
                              && this.elements.length == 1
                              && this.elements[0].value == '&'
                              && (   this.elements[0].combinator.value == ' '
                                  || this.elements[0].combinator.value == '');

  ///
  Selector eval(Env env) {
    bool evaldCondition;
    if (this.condition != null) evaldCondition = this.condition.eval(env); //evaldCondition null is ok
    List<Element> elements = this.elements;
    List<Node> extendList = this.extendList;

    if (elements != null) elements = elements.map((e)=> e.eval(env)).toList();
    if (extendList != null) extendList = extendList.map((extend) => extend.eval(env)).toList();

    return this.createDerived(elements, extendList, evaldCondition);

//    eval: function (env) {
//        var evaldCondition = this.condition && this.condition.eval(env),
//            elements = this.elements, extendList = this.extendList;
//
//        elements = elements && elements.map(function (e) { return e.eval(env); });
//        extendList = extendList && extendList.map(function(extend) { return extend.eval(env); });
//
//        return this.createDerived(elements, extendList, evaldCondition);
//    },
  }

  ///
  /// Writes Selector as String in [output]:
  ///  ' selector'. White space prefixed.
  /// #
  void genCSS(Env env, Output output) {
    Element element;

    if ((env == null || !isTrue(env.firstSelector)) && this.elements[0].combinator.value == '') {
      output.addFull(' ', this.currentFileInfo, this.index);
    }
    if (!isNotEmpty(this._css)) {
      // TODO (js) caching? speed comparison?
      for (int i = 0; i < this.elements.length; i++) {
        element = this.elements[i];
        element.genCSS(env, output);
      }
    }

//    genCSS: function (env, output) {
//        var i, element;
//        if ((!env || !env.firstSelector) && this.elements[0].combinator.value === "") {
//            output.add(' ', this.currentFileInfo, this.index);
//        }
//        if (!this._css) {
//            //TODO caching? speed comparison?
//            for(i = 0; i < this.elements.length; i++) {
//                element = this.elements[i];
//                element.genCSS(env, output);
//            }
//        }
//    },
  }

//    toCSS: tree.toCSS,


  //--- MarkReferencedNode

  ///
  void markReferenced() {
    this.isReferenced = true;
  }

  ///
  bool getIsReferenced() => !this.currentFileInfo.reference || isTrue(this.isReferenced);

  ///
  bool getIsOutput() => this.evaldCondition;
}