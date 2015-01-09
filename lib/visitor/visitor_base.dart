library visitor.less;

import 'dart:async';
import '../less/env.dart';
import '../less/less_error.dart';
import '../nodejs/nodejs.dart';
import '../tree/tree.dart';

part 'extend_finder_visitor.dart';
part 'join_selector_visitor.dart';
part 'import_visitor.dart';
part 'process_extends_visitor.dart';
part 'to_css_visitor.dart';
part 'visitor.dart';

class VisitorBase {
  bool isPreEvalVisitor = false; //plugins
  bool isPreVisitor = false; //plugins
  bool isReplacing = false;

  run(root){}

  static Node noop(node) => node; //TODO delete not used


   /// func visitor.visit distribuitor
   Function visitFtn(Node node) => null;

   /// funcOut visitor.visit distribuitor
   Function visitFtnOut(Node node) => null;

   ///
   error({int index, String type, String message, String filename}) {
     LessError error = new LessError(
         index: index,
         type: type,
         message: message,
         filename: filename
         );
     throw new LessExceptionError(error);
   }

}

class VisitArgs {
  bool visitDeeper;

  VisitArgs(bool this.visitDeeper);
}