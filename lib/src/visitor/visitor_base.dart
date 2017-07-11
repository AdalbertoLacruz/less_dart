library visitor.less;

import 'dart:async';
import 'package:meta/meta.dart';
import '../contexts.dart';
import '../environment/environment.dart';
import '../import_manager.dart';
import '../less_error.dart';
import '../less_options.dart';
import '../logger.dart';
import '../plugins/plugins.dart';
import '../tree/tree.dart';

part 'css_visitor_utils.dart';
part 'extend_finder_visitor.dart';
part 'ignition_visitor.dart';
part 'join_selector_visitor.dart';
part 'import_detector.dart';
part 'import_visitor.dart';
part 'process_extends_visitor.dart';
part 'set_tree_visibility_visitor.dart';
part 'to_css_visitor.dart';
part 'visitor.dart';

///
abstract class VisitorBase {
  ///
  bool isPreEvalVisitor = false; //plugins
  ///
  bool isPreVisitor = false; //plugins
  ///
  bool isReplacing = false;

  ///
  Ruleset run(Ruleset root) => null;

  /// func visitor.visit distribuitor
  Function visitFtn(Node node) => null;

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) => null;

  ///
  void error({int index, String type, String message, String filename}) {
    throw new LessExceptionError(new LessError(
         index: index,
         type: type,
         message: message,
         filename: filename));
  }

  ///
  @virtual
  dynamic visit(dynamic node) => node;

  ///
  List<T> visitArray<T>(List<T> nodes, {bool nonReplacing = false}) => nodes;
}

///
class VisitArgs {
  ///
  bool visitDeeper;

  ///
  VisitArgs({bool this.visitDeeper});
}
