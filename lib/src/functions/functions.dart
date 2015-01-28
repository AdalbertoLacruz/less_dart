library functions.less;

import 'dart:io';
import 'dart:math' as math;
import 'dart:mirrors';

import '../contexts.dart';
import '../file_info.dart';
import '../less_error.dart';
import '../environment/environment.dart';
import '../nodejs/nodejs.dart';
import '../tree/tree.dart';

part 'color_blend.dart';
part 'color_functions.dart';
part 'data_uri_functions.dart';
part 'default_func.dart';
part 'function_caller.dart';
part 'function_base.dart';
part 'math_functions.dart';
part 'number_functions.dart';
part 'string_functions.dart';
part 'svg_functions.dart';
part 'types_functions.dart';

//TODO Move to node base class 2.2.0
///
/// Adjust the precision of [value] according to [env].numPrecision.
/// 8 By default.
/// #
num fround(Contexts env, num value) {  //TODO return string
if (value is int) return value;

//precision
int p = (env != null) ? getValueOrDefault(env.numPrecision, 8) : null;

// add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
double result = value + 2e-16;
return (p == null) ? value : double.parse(result.toStringAsFixed(p));

//tree.fround = function(env, value) {
//    var p = env && env.numPrecision;
//    //add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
//    return (p == null) ? value : Number((value + 2e-16).toFixed(p));
//};
}