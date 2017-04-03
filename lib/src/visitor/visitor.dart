//source: less/visitor.js 2.5.0

part of visitor.less;

class Visitor extends VisitorBase {
  VisitorBase _implementation; //Join_Selector_visitor, ...
  VisitArgs   _visitArgs = new VisitArgs(true);

  ///
  Visitor(VisitorBase this._implementation);

  /// Process a [node] and the subtree. node is Node | String
  @override
  dynamic visit(dynamic node) {
    if (node == null) return node;
    if (node is! Node) return node;

    dynamic _node = node;

    _visitArgs.visitDeeper = true;

    final Function func = _implementation.visitFtn(_node);
    final Function funcOut = _implementation.visitFtnOut(_node);

    if (func != null) {
      final dynamic newNode = func(_node, _visitArgs); //Node or List
      if (_implementation.isReplacing) _node = newNode;
    }

    if (this._visitArgs.visitDeeper && _node != null && (_node is Node)) {
      _node.accept(this);
    }

    if (funcOut != null) funcOut(_node);

    return _node;

//2.3.1
//  visit: function(node) {
//      if (!node) {
//          return node;
//      }
//
//      var nodeTypeIndex = node.typeIndex;
//      if (!nodeTypeIndex) {
//          return node;
//      }
//
//      var visitFnCache = this._visitFnCache,
//          impl = this._implementation,
//          aryIndx = nodeTypeIndex << 1,
//          outAryIndex = aryIndx | 1,
//          func = visitFnCache[aryIndx],
//          funcOut = visitFnCache[outAryIndex],
//          visitArgs = _visitArgs,
//          fnName;
//
//      visitArgs.visitDeeper = true;
//
//      if (!func) {
//          fnName = "visit" + node.type;
//          func = impl[fnName] || _noop;
//          funcOut = impl[fnName + "Out"] || _noop;
//          visitFnCache[aryIndx] = func;
//          visitFnCache[outAryIndex] = funcOut;
//      }
//
//      if (func !== _noop) {
//          var newNode = func.call(impl, node, visitArgs);
//          if (impl.isReplacing) {
//              node = newNode;
//          }
//      }
//
//      if (visitArgs.visitDeeper && node && node.accept) {
//          node.accept(this);
//      }
//
//      if (funcOut != _noop) {
//          funcOut.call(impl, node);
//      }
//
//      return node;
//  },
  }

  ///
  /// [nodes] List<Node> | List<List<>> | List<MixinArgs> ...
  ///
  List<T> visitArray<T>(List<T> nodes, [bool nonReplacing = false]) {
    if (nodes == null) return nodes;

    // Non-replacing
    if (nonReplacing || !_implementation.isReplacing) {
      for (int i = 0; i < nodes.length; i++) visit(nodes[i]);
      return nodes;
    }

    // Replacing
    List<T> out = <T>[];
    for (int i = 0; i < nodes.length; i++) {
      final dynamic evald = visit(nodes[i]); //Node | List<Node>
      if (evald == null) continue;

      if (evald is! List) {
        out.add(evald);
      } else if (evald.isNotEmpty) {
        out = flatten(evald, out);
      }
    }
    return out;

//2.3.1
//  visitArray: function(nodes, nonReplacing) {
//      if (!nodes) {
//          return nodes;
//      }
//
//      var cnt = nodes.length, i;
//
//      // Non-replacing
//      if (nonReplacing || !this._implementation.isReplacing) {
//          for (i = 0; i < cnt; i++) {
//              this.visit(nodes[i]);
//          }
//          return nodes;
//      }
//
//      // Replacing
//      var out = [];
//      for (i = 0; i < cnt; i++) {
//          var evald = this.visit(nodes[i]);
//          if (evald === undefined) { continue; }
//          if (!evald.splice) {
//              out.push(evald);
//          } else if (evald.length) {
//              this.flatten(evald, out);
//          }
//      }
//      return out;
//  },
  }

  ///
  /// Converts a mix of Node and List<Node> to List<Node>
  /// T is Node | MixinArgs (for visitArray commpatibility)
  /// arr == [Node, [Node, Node...]] -> [Node, Node, Node, ...]
  /// MixinArgs don't need to be flatten and don't must be here
  ///
  List<T> flatten<T>(List<T> arr, List<T> out) {
    List<T> _out = out ?? <T>[];

    T item; //Node or List
    int nestedCnt;
    dynamic nestedItem;

    for (int i = 0 ; i < arr.length; i++) {
      item = arr[i];
      if (item == null) continue;

      if (item is! List) { //Node
        _out.add(item);
        continue;
      }

      //item is List
      nestedCnt = (item as List<dynamic>).length;
      for (int j = 0; j < nestedCnt; j++) {
        nestedItem = (item as List<dynamic>)[j];
        if (nestedItem == null) continue;
        if (nestedItem is! List) { //Node
          _out.add(nestedItem);
        } else if (nestedItem.isNotEmpty) {
          _out = flatten<T>(nestedItem, _out);
        }
      }
    }

    return _out;

//2.3.1
//  flatten: function(arr, out) {
//      if (!out) {
//          out = [];
//      }
//
//      var cnt, i, item,
//          nestedCnt, j, nestedItem;
//
//      for (i = 0, cnt = arr.length; i < cnt; i++) {
//          item = arr[i];
//          if (item === undefined) {
//              continue;
//          }
//          if (!item.splice) {
//              out.push(item);
//              continue;
//          }
//
//          for (j = 0, nestedCnt = item.length; j < nestedCnt; j++) {
//              nestedItem = item[j];
//              if (nestedItem === undefined) {
//                  continue;
//              }
//              if (!nestedItem.splice) {
//                  out.push(nestedItem);
//              } else if (nestedItem.length) {
//                  this.flatten(nestedItem, out);
//              }
//          }
//      }
//
//      return out;
//  }
  }

  //@override
  //T run(T root) => null;
}
