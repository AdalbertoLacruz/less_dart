//source: less/data/unit-conversions.js 2.5.0

library unitconversions.less;

import 'dart:math' as math;

/// http://www.w3.org/TR/css3-values/#absolute-lengths
class UnitConversions {
  ///
  static Map<String, Map<String, double>> groups = <String, Map<String, double>>{
    'length': length,
    'duration': duration,
    'angle': angle};

  ///
  static Map<String, double> length = <String, double>{
     'm': 1.0,
    'cm': 0.01,
    'mm': 0.001,
    'in': 0.0254,
    'px': 0.0254 / 96,
    'pt': 0.0254 / 72,
    'pc': 0.0254 / 72 * 12
  };

  ///
  static Map<String, double> duration = <String, double>{
     's': 1.0,
    'ms': 0.001
  };

  ///
  static Map<String, double> angle = <String, double>{
     'rad':  1 / (2 * math.pi),
     'deg':  1 / 360,
    'grad': 1 / 400,
    'turn': 1.0
  };

//2.2.0
//  module.exports = {
//      length: {
//          'm': 1,
//          'cm': 0.01,
//          'mm': 0.001,
//          'in': 0.0254,
//          'px': 0.0254 / 96,
//          'pt': 0.0254 / 72,
//          'pc': 0.0254 / 72 * 12
//      },
//      duration: {
//          's': 1,
//          'ms': 0.001
//      },
//      angle: {
//          'rad': 1/(2*Math.PI),
//          'deg': 1/360,
//          'grad': 1/400,
//          'turn': 1
//      }
//  };
}
