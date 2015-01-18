//source: less/tree/color.js 1.7.5

part of tree.less;

/*
 * RGB Colors - #ff0014, #eee
 */
class Color extends Node implements CompareNode, EvalNode, OperateNode, ToCSSNode {
  List<num> rgb;
  num alpha;

  bool isTransparentKeyword = false;
  String keyword; //2.2.0
  static String transparentKeyword = "transparent";

  final String type = 'Color';

  num get r => this.rgb[0];
  num get g => this.rgb[1];
  num get b => this.rgb[2];

  /**
   * The end goal here, is to parse the arguments
   * into an integer triplet, such as `128, 255, 0`
   *
   * This facilitates operations and conversions.
   *
   * [rgb] could be a List<int> [128, 255, 0]
   * or String length=6 # 'deb887' or length=3 # 'f01'.
   * [alpha] 0 < alpha < 1. Default = 1.
   */
  Color(rgb, [num this.alpha = 1]){
    RegExp hex6 = new RegExp('.{2}');

    if (rgb is List<int>) {           //[0, 0 , 0]
      this.rgb = rgb;
    } else if (rgb.length == 6 ) {    //  # 'deb887'
      this.rgb = hex6.allMatches(rgb).map((c) => int.parse(c[0], radix: 16)).toList();
    } else {                          // # 'f01'
      this.rgb = rgb.split('').map((c) => int.parse(c + c, radix: 16)).toList();
    }

//  tree.Color = function (rgb, a) {
//      if (Array.isArray(rgb)) { //[0, 0 , 0]
//          this.rgb = rgb;
//      } else if (rgb.length == 6) {  //  # 'deb887'
//          this.rgb = rgb.match(/.{2}/g).map(function (c) {
//              return parseInt(c, 16);
//          });
//      } else {
//          this.rgb = rgb.split('').map(function (c) { // '#f01'
//              return parseInt(c + c, 16); /c = f -> cc (string add)
//          });
//      }
//      this.alpha = typeof(a) === 'number' ? a : 1;
//  };
//
  }

  factory Color.fromKeyword(String keyword){
    keyword = keyword.toLowerCase();

    // detect named color
    if(colors.containsKey(keyword)) return new Color(colors[keyword].substring(1));

    if (keyword == transparentKeyword) return new Color([0, 0, 0], 0)..isTransparentKeyword = true;

    return null;

//
//  tree.Color.fromKeyword = function(keyword) {
//      keyword = keyword.toLowerCase();
//
//      if (tree.colors.hasOwnProperty(keyword)) {
//          // detect named color
//          return new(tree.Color)(tree.colors[keyword].slice(1));
//      }
//      if (keyword === transparentKeyword) {
//          var transparent = new(tree.Color)([0, 0, 0], 0);
//          transparent.isTransparentKeyword = true;
//          return transparent;
//      }
//  };
  }

  ///
  Node eval(env) => this;

  /// Calculates the luma (perceptual brightness) of a color object.
  double luma() {
    double r = this.r / 255;
    double g = this.g / 255;
    double b = this.b / 255;

    r = (r <= 0.03928) ? r / 12.92 : math.pow(((r + 0.055) / 1.055), 2.4);
    g = (g <= 0.03928) ? g / 12.92 : math.pow(((g + 0.055) / 1.055), 2.4);
    b = (b <= 0.03928) ? b / 12.92 : math.pow(((b + 0.055) / 1.055), 2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;

//      luma: function () {
//          var r = this.rgb[0] / 255,
//              g = this.rgb[1] / 255,
//              b = this.rgb[2] / 255;
//
//          r = (r <= 0.03928) ? r / 12.92 : Math.pow(((r + 0.055) / 1.055), 2.4);
//          g = (g <= 0.03928) ? g / 12.92 : Math.pow(((g + 0.055) / 1.055), 2.4);
//          b = (b <= 0.03928) ? b / 12.92 : Math.pow(((b + 0.055) / 1.055), 2.4);
//
//          return 0.2126 * r + 0.7152 * g + 0.0722 * b;
//      },
  }

  ///
  void genCSS(Env env, Output output) {
    output.add(this.toCSS(env));
  }

  /// returns this color as string. Transparent, #rrggbb, #rgb. #
  String toCSS(env) {  // function (env, doNotCompress) {//doNotCompress !!!
    var compress = (env != null) ? env.compress : false;
    var alpha = fround(env, this.alpha); //TODO review fround

    // If we have some transparency, the only way to represent it
    // is via `rgba`. Otherwise, we use the hex representation,
    // which has better compatibility with older browsers.
    // Values are capped between `0` and `255`, rounded and zero-padded.
    if (alpha < 1) {
      if (alpha == 0 && this.isTransparentKeyword) return transparentKeyword;
      List resultList = this.rgb.map((c){
        return clamp(c.round(), 255);
      }).toList();
      resultList.add(numToString(clamp(alpha, 1)));

      // convert to string 0.1 -> '0.1', 0.0 -> '0'
//      resultList = resultList.map((num c){
//        int i = c.toInt();
//        return (c == i) ? i.toString() : c.toString();
//      }).toList();

      return 'rgba(' + resultList.join(',' + (compress ? '' : ' ')) + ')';
    } else {
      String color = this.toRGB();
      if (compress) {
        List splitcolor = color.split('');

        // Convert color to short format
        if (splitcolor[1] == splitcolor[2] && splitcolor[3] == splitcolor[4] && splitcolor[5] == splitcolor[6]) {
          color = '#' + splitcolor[1] + splitcolor[3] + splitcolor[5];
        }
      }
      return color;
    }


//      toCSS: function (env, doNotCompress) {
//          var compress = env && env.compress && !doNotCompress,
//              alpha = tree.fround(env, this.alpha);
//
//          // If we have some transparency, the only way to represent it
//          // is via `rgba`. Otherwise, we use the hex representation,
//          // which has better compatibility with older browsers.
//          // Values are capped between `0` and `255`, rounded and zero-padded.
//          if (alpha < 1) {
//              if (alpha === 0 && this.isTransparentKeyword) {
//                  return transparentKeyword;
//              }
//              return "rgba(" + this.rgb.map(function (c) {
//                  return clamp(Math.round(c), 255);
//              }).concat(clamp(alpha, 1))
//                  .join(',' + (compress ? '' : ' ')) + ")";
//          } else {
//              var color = this.toRGB();
//
//              if (compress) {
//                  var splitcolor = color.split('');
//
//                  // Convert color to short format
//                  if (splitcolor[1] === splitcolor[2] && splitcolor[3] === splitcolor[4] && splitcolor[5] === splitcolor[6]) {
//                      color = '#' + splitcolor[1] + splitcolor[3] + splitcolor[5];
//                  }
//              }
//
//              return color;
//          }
//      },
  }


//--- OperateNode

  ///
  /// Operations have to be done per-channel, if not,
  /// channels will spill onto each other. Once we have
  /// our result, in the form of an integer triplet,
  /// we create a new Color node to hold the result.
  ///
  Color operate(Env env, String op, Color other) {
    List<num> rgb = [0, 0, 0];
    num alpha = this.alpha * (1 - other.alpha) + other.alpha;
    for (int c = 0; c < 3; c++) {
      rgb[c] = Operation.operateExec(env, op, this.rgb[c], other.rgb[c]);
    }
    return new Color(rgb, alpha);

//      operate: function (env, op, other) {
//          var rgb = [];
//          var alpha = this.alpha * (1 - other.alpha) + other.alpha;
//          for (var c = 0; c < 3; c++) {
//              rgb[c] = tree.operate(env, op, this.rgb[c], other.rgb[c]);
//          }
//          return new(tree.Color)(rgb, alpha);
//      },
  }

  ///
  /// Returns this color as String #rrggbb.
  /// #
  String toRGB() => toHex(this.rgb);

  /// returns this Color as HSLA
  HSLType toHSL() {
    double r = this.r / 255;
    double g = this.g / 255;
    double b = this.b / 255;
    double a = this.alpha.toDouble();

    List maxList = [['r', r], ['g', g], ['b', b]]..sort((x, y) => y[1] - x[1]); // big to little
    double max = maxList.first[1];
    double min = maxList[2][1];
    double h;
    double s;
    double l = (max + min) / 2;
    double d = max - min;

    if (max == min) {
      h = s = 0.0;
    } else {
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

      switch (maxList.first[0]) {
        case 'r':
          h = (g - b) / d + (g < b ? 6 : 0);
          break;
        case 'g':
          h = (b - r) / d + 2;
          break;
        case 'b':
          h = (r - g) / d + 4;
          break;
      }
      h /= 6;
    }

    return new HSLType(h: h * 360, s: s, l: l, a: a);

//      toHSL: function () {
//          var r = this.rgb[0] / 255,
//              g = this.rgb[1] / 255,
//              b = this.rgb[2] / 255,
//              a = this.alpha;
//
//          var max = Math.max(r, g, b), min = Math.min(r, g, b);
//          var h, s, l = (max + min) / 2, d = max - min;
//
//          if (max === min) {
//              h = s = 0;
//          } else {
//              s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
//
//              switch (max) {
//                  case r: h = (g - b) / d + (g < b ? 6 : 0); break;
//                  case g: h = (b - r) / d + 2;               break;
//                  case b: h = (r - g) / d + 4;               break;
//              }
//              h /= 6;
//          }
//          return { h: h * 360, s: s, l: l, a: a };
//      },
  }

  ///
  /*
   * Adapted from
   * http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
   */
  HSVType toHSV() {
    double r = this.r / 255;
    double g = this.g / 255;
    double b = this.b / 255;
    double a = this.alpha;

    List maxList = [['r', r], ['g', g], ['b', b]]..sort((x, y) => y[1] - x[1]); // big to little
    double max = maxList.first[1];
    double min = maxList[2][1];
    double h;
    double s;
    double v = max;

    double d = max - min;
    if (max == 0.0) {
      s = 0.0;
    } else {
      s = d / max;
    }

    if (max == min) {
      h = 0.0;
    } else {
      switch (maxList.first[0]) {
        case 'r':
          h = (g - b) / d + (g < b ? 6 : 0);
          break;
        case 'g':
          h = (b - r) / d + 2;
          break;
        case 'b':
          h = (r - g) / d + 4;
          break;
      }
      h /= 6;
    }

    return new HSVType(h: h * 360, s: s, v: v, a: a);

//      toHSV: function () {
//          var r = this.rgb[0] / 255,
//              g = this.rgb[1] / 255,
//              b = this.rgb[2] / 255,
//              a = this.alpha;
//
//          var max = Math.max(r, g, b), min = Math.min(r, g, b);
//          var h, s, v = max;
//
//          var d = max - min;
//          if (max === 0) {
//              s = 0;
//          } else {
//              s = d / max;
//          }
//
//          if (max === min) {
//              h = 0;
//          } else {
//              switch(max){
//                  case r: h = (g - b) / d + (g < b ? 6 : 0); break;
//                  case g: h = (b - r) / d + 2; break;
//                  case b: h = (r - g) / d + 4; break;
//              }
//              h /= 6;
//          }
//          return { h: h * 360, s: s, v: v, a: a };
//      },
  }

  ///
  /// Returns a String such as #aarrggbb
  /// #
  String toARGB() => toHex([this.alpha * 255]..addAll(this.rgb));


//--- CompareNode

  ///
  /// Returns -1, 0 for different, equal
  /// #
  int compare(Node x) {
    if (x is! Color) return -1;

    Color xx = x as Color;
    return (xx.r == this.r &&
            xx.g == this.g &&
            xx.b == this.b &&
            xx.alpha == this.alpha) ? 0 : -1;

//      compare: function (x) {
//          if (!x.rgb) {
//              return -1;
//          }
//
//          return (x.rgb[0] === this.rgb[0] &&
//              x.rgb[1] === this.rgb[1] &&
//              x.rgb[2] === this.rgb[2] &&
//              x.alpha === this.alpha) ? 0 : -1;
//      }
//  };
  }

  /// returns a String #rrggbb.
  /// [v] is a List<num> = [r, g, b] or [r, b, b, a].
  // static?
  String toHex(List<num> v) {
    List<String> resultList = v.map((num c){
      int r = c.round().clamp(0, 255);
      return (r < 16 ? '0' : '') + r.toRadixString(16);
    }).toList();
    return '#' + resultList.join('');

//  function toHex(v) {
//      return '#' + v.map(function (c) {
//          c = clamp(Math.round(c), 255);
//          return (c < 16 ? '0' : '') + c.toString(16);
//      }).join('');
//  }
  }

  /// returns num v in the range [0 v max]. #
  // static?
  num clamp(num v, num max) => v.clamp(0, max);

//  function clamp(v, max) {
//      return Math.min(Math.max(v, 0), max);
//  }

  // Dart only
  void genTree(Env env, Output output) {
    String tabStr = '  ' * env.tabLevel;
    String result = 'null';
    if (this.rgb != null)  result = toRGB();

    output.add('${tabStr}$type ($result)\n');
  }
}

class HSLType {
  double h;
  double s;
  double l;
  double a;

  HSLType({this.h, this.s, this.l, this.a});
}

class HSVType {
  double h;
  double s;
  double v;
  double a;

  HSVType({this.h, this.s, this.v, this.a});
}