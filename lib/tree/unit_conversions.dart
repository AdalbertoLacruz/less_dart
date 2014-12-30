//source: less/tree/dimension.js 1.7.5

part of tree.less;

class UnitConversions {
  static Map<String, Map> groups = {
    'length': length,
    'duration': duration,
    'angle': angle};

  static Map<String, double> length = {
     'm': 1,
    'cm': 0.01,
    'mm': 0.001,
    'in': 0.0254,
    'px': 0.0254 / 96,
    'pt': 0.0254 / 72,
    'pc': 0.0254 / 72 * 12
  };
  static Map<String, double> duration = {
     's': 1,
    'ms': 0.001
  };
  static Map<String, double> angle = {
    'rad': 1/(2*math.PI),
    'deg': 1/360,
    'grad': 1/400,
    'turn': 1
  };

  static group(String group) => groups[group]; //TODO delete?

//    switch (group) {
//      case 'length':
//        return length;
//      case 'duration':
//        return duration;
//      case 'angle':
//        return angle;
//    }
//    return null;


// ************************************************* UnitConversions ******************

//// http://www.w3.org/TR/css3-values/#absolute-lengths
//  tree.UnitConversions = {
//      length: {
//           'm': 1,
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
//
}
