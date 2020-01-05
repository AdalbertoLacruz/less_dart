//source: less/tree/color.js 3.8.0 20180808

part of tree.less;

///
/// RGB Colors: #rgb #rgba #rrggbb #rrggbbaa
///
class Color extends Node implements CompareNode, OperateNode<Color> {
  @override
  final String name = null;

  @override
  final String type = 'Color';

  /// original form  (#fea) or named color (blue) to return to CSS
  /// Color space (rgb, hsl) from function operations, to preserve in output
  @override
  covariant String value;

  /// 0 to 1.0
  num alpha;

  /// [r, g, b]. Not always int.
  List<num> rgb;

  ///
  static String transparentKeyword = 'transparent';

  ///
  /// The end goal here, is to parse the arguments
  /// into an integer triplet, such as `128, 255, 0`
  ///
  /// This facilitates operations and conversions.
  ///
  /// [rgb] is a String (The caller assure the format is correct):
  ///   length=8 # 'rrggbbaa'
  ///   length=6 # 'rrggbb'
  ///   length=4 # 'rgba'
  ///   length=3 # 'rgb'.
  ///
  /// [alpha] 0 < alpha < 1. Default = 1.
  ///
  /// [originalForm] returned to CSS if color is not processed: #rgb or #rrggbb.
  ///
  Color(String rgb, [alpha = 1, String originalForm]) {
    // 0x0000000U -> 0x000000UU
    int fToff(int unit) => (unit << 4) | unit;

    this.alpha = (alpha ?? 1).clamp(0, 1);
    final len = rgb.length;
    var val = int.parse(rgb, radix: 16);

    if (len >= 6) {
      // #rrggbbaa => alpha 0xrrggbb
      if (len == 8) {
        this.alpha = (val & 0x000000ff) / 0xff;
        val = (val & 0xffffff00) >> 8;
      }
      // val = 0xrrggbb
      this.rgb = <num>[
        (0x00ff0000 & val) >> 16,
        (0x0000ff00 & val) >> 8,
        (0x000000ff & val) >> 0
      ];
    } else {
      // #rgba => alpha 0xrgb
      if (len == 4) {
        this.alpha = fToff(val & 0x0000000f) / 0xff;
        val = (val & 0x0000fff0) >> 4;
      }
      // 0xrgb
      this.rgb = <num>[
        fToff((val & 0x00000f00) >> 8),
        fToff((val & 0x000000f0) >> 4),
        fToff((val & 0x0000000f) >> 0)
      ];
    }

    if (originalForm != null) value = originalForm;

// 3.8.0 20180729
//  var Color = function (rgb, a, originalForm) {
//      var self = this;
//      //
//      // The end goal here, is to parse the arguments
//      // into an integer triplet, such as `128, 255, 0`
//      //
//      // This facilitates operations and conversions.
//      //
//      if (Array.isArray(rgb)) {
//          this.rgb = rgb;
//      } else if (rgb.length >= 6) {
//          this.rgb = [];
//          rgb.match(/.{2}/g).map(function (c, i) {
//              if (i < 3) {
//                  self.rgb.push(parseInt(c, 16));
//              } else {
//                  self.alpha = (parseInt(c, 16)) / 255;
//              }
//          });
//      } else {
//          this.rgb = [];
//          rgb.split('').map(function (c, i) {
//              if (i < 3) {
//                  self.rgb.push(parseInt(c + c, 16));
//              } else {
//                  self.alpha = (parseInt(c + c, 16)) / 255;
//              }
//          });
//      }
//      this.alpha = this.alpha || (typeof a === 'number' ? a : 1);
//      if (typeof originalForm !== 'undefined') {
//          this.value = originalForm;
//      }
//  };
  }

  ///
  /// [rgb] is a List<num> [128, 255, 0] or [62.2, 125.5, 67]
  /// The decimal arguments came from color operations
  ///
  /// [alpha] 0 < alpha < 1. Default = 1.
  ///
  Color.fromList(rgb, [alpha = 1, String originalForm]) {
    this.rgb = <num>[for (var c in rgb) c.clamp(0, 255)];
    this.alpha = (alpha ?? 1).clamp(0, 1);
    if (originalForm != null) value = originalForm;
  }

  ///
  factory Color.fromKeyword(String keyword) {
    final key = keyword.toLowerCase();
    Color c;
    String colorValue;

    // detect named color
    if ((colorValue = colors[key]) != null) {
      c = Color(colorValue.substring(1))..value = keyword;
    } else if (key == transparentKeyword) {
      c = Color.fromList(<num>[0, 0, 0], 0)..value = keyword;
    }

    return c;

//2.3.1
//  Color.fromKeyword = function(keyword) {
//      var c, key = keyword.toLowerCase();
//      if (colors.hasOwnProperty(key)) {
//          c = new Color(colors[key].slice(1));
//      }
//      else if (key === "transparent") {
//          c = new Color([0, 0, 0], 0);
//      }
//
//      if (c) {
//          c.value = keyword;
//          return c;
//      }
//  };
  }

  /// Alpha without trailing zeros: 0 0.1 1
  String get alphaAsString => NumberFormatter().format(alpha);

  /// red 0 to 255, could be xx.xxx
  num get r => rgb[0];

  /// 0 to 1 -> 0.xxx
  double get red => r / 255;

  /// green 0 to 255, could be xx.xxx
  num get g => rgb[1];

  /// 0 to 1 -> 0.xxx
  double get green => g / 255;

  /// blue 0 to 255, could be xx.xxx
  num get b => rgb[2];

  /// 0 to 1 -> 0.xxx
  double get blue => b / 255;

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'rgb': rgb, 'alpha': alpha};

  ///
  /// Don't use spaces to css
  ///
  bool _isCompress(Contexts context) =>
      (cleanCss != null) || (context?.compress ?? false);

  ///
  @override
  Node eval(Contexts env) => this;

  ///
  /// See https://www.w3.org/TR/WCAG20/#relativeluminancedef
  ///
  static double _linearizeColorComponent(double component) =>
      (component <= 0.03928)
          ? component / 12.92
          : math.pow((component + 0.055) / 1.055, 2.4);

  ///
  /// Calculates the luma (perceptual brightness) of a color object
  /// Value between 0 for darkest and 1 for lightest.
  ///
  double luma() {
    final _r = _linearizeColorComponent(red);
    final _g = _linearizeColorComponent(green);
    final _b = _linearizeColorComponent(blue);

    return 0.2126 * _r + 0.7152 * _g + 0.0722 * _b;

//2.2.0
//  Color.prototype.luma = function () {
//      var r = this.rgb[0] / 255,
//          g = this.rgb[1] / 255,
//          b = this.rgb[2] / 255;
//
//      r = (r <= 0.03928) ? r / 12.92 : Math.pow(((r + 0.055) / 1.055), 2.4);
//      g = (g <= 0.03928) ? g / 12.92 : Math.pow(((g + 0.055) / 1.055), 2.4);
//      b = (b <= 0.03928) ? b / 12.92 : Math.pow(((b + 0.055) / 1.055), 2.4);
//
//      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add(toCSS(context));
  }

  ///
  /// Returns this color as string. Transparent, #rrggbb, #rgb.
  ///
  @override
  String toCSS(Contexts context) {
    // final bool doNotCompress = false; // in js is an argument in toCSS. ??
    if (cleanCss?.compatibility?.properties?.colors ?? false) {
      return toCleanCSS(context);
    }

    final alphaFormatter = AlphaFormatter(context)
      ..removeLeadingZero = cleanCss != null;
    final numberFormatter = NumberFormatter()
      ..precision = context?.numPrecision;

    final compress = context?.compress ?? false; // && !doNotCompress;
    final _alpha = alphaFormatter.adjustPrecision(alpha);

    // `value` is set if this color was originally
    // converted from a named color string so we need
    // to respect this and try to output named color too.

    String colorFunction;
    if (value != null) {
      if (value.startsWith('rgb')) {
        if (_alpha < 1) colorFunction = 'rgba';
      } else if (value.startsWith('hsl')) {
        colorFunction = _alpha < 1 ? 'hsla' : 'hsl';
      } else {
        return value;
      }
    } else {
      if (_alpha < 1) colorFunction = 'rgba';
    }

    List<String> args;
    switch (colorFunction) {
      case 'rgba':
        args = [
          for (var c in rgb) c.round().toString(),
          alphaFormatter.format(_alpha, formatted: true)
        ];
        break;
      case 'hsla':
        args = <String>[alphaFormatter.format(_alpha, formatted: true)];
        continue hsl;
      hsl:
      case 'hsl':
        final color = toHSL();
        args = <String>[
          numberFormatter.format(color.h),
          '${numberFormatter.format(color.s * 100)}%',
          '${numberFormatter.format(color.l * 100)}%',
          ...?args,
        ];
        break;
    }

    // Values are capped between `0` and `255`, rounded and zero-padded.
    if (colorFunction != null) {
      final separator = _isCompress(context) ? ',' : ', ';
      return '$colorFunction(${args.join(separator)})';
    }

    final color = toRGB();
    return compress ? tryHex3(color) : color;

// 3.8.0 20180808
//  Color.prototype.toCSS = function (context, doNotCompress) {
//      var compress = context && context.compress && !doNotCompress, color, alpha,
//          colorFunction, args = [];
//
//      // `value` is set if this color was originally
//      // converted from a named color string so we need
//      // to respect this and try to output named color too.
//      alpha = this.fround(context, this.alpha);
//
//      if (this.value) {
//          if (this.value.indexOf('rgb') === 0) {
//              if (alpha < 1) {
//                  colorFunction = 'rgba';
//              }
//          } else if (this.value.indexOf('hsl') === 0) {
//              if (alpha < 1) {
//                  colorFunction = 'hsla';
//              } else {
//                  colorFunction = 'hsl';
//              }
//          } else {
//              return this.value;
//          }
//      } else {
//          if (alpha < 1) {
//              colorFunction = 'rgba';
//          }
//      }
//
//      switch (colorFunction) {
//          case 'rgba':
//              args = this.rgb.map(function (c) {
//                  return clamp(Math.round(c), 255);
//              }).concat(clamp(alpha, 1));
//              break;
//          case 'hsla':
//              args.push(clamp(alpha, 1));
//          case 'hsl':
//              color = this.toHSL();
//              args = [
//                  this.fround(context, color.h),
//                  this.fround(context, color.s * 100) + '%',
//                  this.fround(context, color.l * 100) + '%'
//              ].concat(args);
//      }
//
//      if (colorFunction) {
//          // Values are capped between `0` and `255`, rounded and zero-padded.
//          return colorFunction + '(' + args.join(',' + (compress ? '' : ' ')) + ')';
//      }
//
//      color = this.toRGB();
//
//      if (compress) {
//          var splitcolor = color.split('');
//
//          // Convert color to short format
//          if (splitcolor[1] === splitcolor[2] && splitcolor[3] === splitcolor[4] && splitcolor[5] === splitcolor[6]) {
//              color = '#' + splitcolor[1] + splitcolor[3] + splitcolor[5];
//          }
//      }
//
//      return color;
//  };
  }

  ///
  /// clean-css output
  ///
  String toCleanCSS(Contexts context) {
    final _alpha = AlphaFormatter(context).adjustPrecision(alpha);
    var color = toRGB();

    if (cleanCss.compatibility.colors.opacity &&
        _alpha == 0 &&
        color == '#000000') {
      return transparentKeyword;
    }
    if (_alpha == 1) {
      final key = getColorKey(color);
      color = tryHex3(color);
      if (key != null) {
        if (key.length < color.length) return key;
        if (key.length == color.length && value != null && key == value) {
          return key;
        }
      }
    }

    return _alpha < 1 ? toRGBFunction(context) : color;
  }

//--- OperateNode

  ///
  /// Operations have to be done per-channel, if not,
  /// channels will spill onto each other. Once we have
  /// our result, in the form of an integer triplet,
  /// we create a new Color node to hold the result.
  ///
  @override
  Color operate(Contexts context, String op, Color other) {
    final alpha = this.alpha * (1 - other.alpha) + other.alpha;

    final rgb = <num>[
      for (var c = 0; c < 3; c++)
        _operate(context, op, this.rgb[c], other.rgb[c])
    ];

    return Color.fromList(rgb, alpha);

//3.0.0 20160714
// Color.prototype.operate = function (context, op, other) {
//     var rgb = new Array(3);
//     var alpha = this.alpha * (1 - other.alpha) + other.alpha;
//     for (var c = 0; c < 3; c++) {
//         rgb[c] = this._operate(context, op, this.rgb[c], other.rgb[c]);
//     }
//     return new Color(rgb, alpha);
// };
  }

  ///
  /// Returns this color as String #rrggbb.
  ///
  String toRGB() {
    final rrggbb = rgb.fold(0x00000000,
        (rr, val) => (rr << 8) | (val.round().toInt() & 0x000000ff)) as int;
    return '#${rrggbb.toRadixString(16).padLeft(6, '0')}';
  }

  ///
  /// Returns this Color as HSLA
  ///
  HSLType toHSL() {
    final _r = red;
    final _g = green;
    final _b = blue;
    final _a = alpha.toDouble();

    final rawMap = <String, double>{'r': _r, 'g': _g, 'b': _b};

    // maxMap = { 'r or g or b': max_value, ..., 'r or g or b': min_value }.
    // Repeated values removed.
    final maxMap = SplayTreeMap<String, double>.of(
        rawMap, (String a, String b) => rawMap[b].compareTo(rawMap[a]));

    final max = maxMap[maxMap.firstKey()];
    final min = maxMap[maxMap.lastKey()];

    final l = (max + min) / 2;
    final d = max - min;

    double h;
    double s;
    if (max == min) {
      h = s = 0.0;
    } else {
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

      // max
      switch (maxMap.firstKey()) {
        case 'r':
          h = (_g - _b) / d + (_g < _b ? 6 : 0);
          break;
        case 'g':
          h = (_b - _r) / d + 2;
          break;
        case 'b':
          h = (_r - _g) / d + 4;
          break;
      }
      h /= 6;
    }

    return HSLType(h: h * 360, s: s, l: l, a: _a);

//2.2.0
//  Color.prototype.toHSL = function () {
//      var r = this.rgb[0] / 255,
//          g = this.rgb[1] / 255,
//          b = this.rgb[2] / 255,
//          a = this.alpha;
//
//      var max = Math.max(r, g, b), min = Math.min(r, g, b);
//      var h, s, l = (max + min) / 2, d = max - min;
//
//      if (max === min) {
//          h = s = 0;
//      } else {
//          s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
//
//          switch (max) {
//              case r: h = (g - b) / d + (g < b ? 6 : 0); break;
//              case g: h = (b - r) / d + 2;               break;
//              case b: h = (r - g) / d + 4;               break;
//          }
//          h /= 6;
//      }
//      return { h: h * 360, s: s, l: l, a: a };
//  };
  }

  ///
  /*
   * Adapted from
   * http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
   */
  HSVType toHSV() {
    final _r = red;
    final _g = green;
    final _b = blue;
    final _a = alpha.toDouble();

    final rawMap = <String, double>{'r': _r, 'g': _g, 'b': _b};

    // maxMap = { 'r or g or b': max_value, ..., 'r or g or b': min_value }.
    // Repeated values removed.
    final maxMap = SplayTreeMap<String, double>.of(
        rawMap, (String a, String b) => rawMap[b].compareTo(rawMap[a]));

    final max = maxMap[maxMap.firstKey()];
    final min = maxMap[maxMap.lastKey()];

    final v = max;
    final d = max - min;

    double h;
    double s;
    if (max == 0.0) {
      s = 0.0;
    } else {
      s = d / max;
    }

    if (max == min) {
      h = 0.0;
    } else {
      // max
      switch (maxMap.firstKey()) {
        case 'r':
          h = (_g - _b) / d + (_g < _b ? 6 : 0);
          break;
        case 'g':
          h = (_b - _r) / d + 2;
          break;
        case 'b':
          h = (_r - _g) / d + 4;
          break;
      }
      h /= 6;
    }

    return HSVType(h: h * 360, s: s, v: v, a: _a);

//2.2.0
//  Color.prototype.toHSV = function () {
//      var r = this.rgb[0] / 255,
//          g = this.rgb[1] / 255,
//          b = this.rgb[2] / 255,
//          a = this.alpha;
//
//      var max = Math.max(r, g, b), min = Math.min(r, g, b);
//      var h, s, v = max;
//
//      var d = max - min;
//      if (max === 0) {
//          s = 0;
//      } else {
//          s = d / max;
//      }
//
//      if (max === min) {
//          h = 0;
//      } else {
//          switch(max){
//              case r: h = (g - b) / d + (g < b ? 6 : 0); break;
//              case g: h = (b - r) / d + 2; break;
//              case b: h = (r - g) / d + 4; break;
//          }
//          h /= 6;
//      }
//      return { h: h * 360, s: s, v: v, a: a };
//  };
  }

  ///
  /// Returns a String such as #aarrggbb
  ///
  String toARGB() {
    final aarrggbb = rgb.fold((alpha * 255).round().toInt() & 0x000000ff,
        (rr, val) => (rr << 8) | (val.round().toInt() & 0x000000ff)) as int;
    return '#${aarrggbb.toRadixString(16).padLeft(8, '0')}';
  }

//--- CompareNode

  ///
  /// Returns -1, 0 for different, equal
  ///
  @override
  int compare(Node xx) {
    if (xx is! Color) return -1;

    final Color x = xx;
    return (x.r == r && x.g == g && x.b == b && x.alpha == alpha) ? 0 : null;

//2.2.0
//  Color.prototype.compare = function (x) {
//      return (x.rgb &&
//          x.rgb[0] === this.rgb[0] &&
//          x.rgb[1] === this.rgb[1] &&
//          x.rgb[2] === this.rgb[2] &&
//          x.alpha  === this.alpha) ? 0 : undefined;
//  };
  }
//
//  ///
//  /// Returns a String #rrggbb.
//  /// [v] is a List<num> = [r, g, b] or [r, g, b, a].
//  ///
//  String toHex(List<num> v) => v.fold(
//      '#',
//      (String result, num c) =>
//          result +
//          c.round().clamp(0, 255).toInt().toRadixString(16).padLeft(2, '0'));

  //2.2.0
  //  function toHex(v) {
  //      return '#' + v.map(function (c) {
  //          c = clamp(Math.round(c), 255);
  //          return (c < 16 ? '0' : '') + c.toString(16);
  //      }).join('');
  //  }

  ///
  /// [hex] == '#rrggbb' => '#rgb'
  /// else return unchanged
  ///
  String tryHex3(String hex) => (hex.length == 7 &&
          hex[1] == hex[2] &&
          hex[3] == hex[4] &&
          hex[5] == hex[6])
      ? '#${hex[1]}${hex[3]}${hex[5]}'
      : hex;

  ///
  /// => 'rgba(r, g, b, a)'
  ///
  String toRGBFunction(Contexts context) {
    final formatter = AlphaFormatter(context)
      ..removeLeadingZero = cleanCss != null;
    final separator = _isCompress(context) ? ',' : ', ';

    final arguments = <String>[
      for (var c in rgb) c.round().toString(),
      formatter.format(alpha),
    ].join(separator);

    return 'rgba($arguments)';
  }

  ///
  /// [value] == '#rrggbb' returns the color key (color name)
  ///
  static String getColorKey(String value) => colors.getKey(value);

  @override
  String toString() => toCSS(null);
}

///
class HSLType {
  ///
  double h;

  ///
  double s;

  ///
  double l;

  ///
  double a;

  ///
  HSLType({this.h, this.s, this.l, this.a});
}

///
class HSVType {
  ///
  double h;

  ///
  double s;

  ///
  double v;

  ///
  double a;

  ///
  HSVType({this.h, this.s, this.v, this.a});
}

///
/// Formatter for alpha in color
///
class AlphaFormatter extends NumberFormatter {
  /// alpha from num to string
  AlphaFormatter(Contexts context) : super() {
    precision = context?.numPrecision;
  }
}
