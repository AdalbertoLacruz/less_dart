// source: lib/less/functions/color.js 3.9.0 20190711

part of functions.less;

///
class ColorFunctions extends FunctionBase {
  ///
  /// Returns [val] clamped to be in the range 0..val..1.
  /// Maintains type
  ///
  @defineMethodSkip
  T clamp<T extends num>(T val) => val.clamp(0.0, 1.0) as T;

//  function clamp(val) {
//      return Math.min(1, Math.max(0, val));
//  }
  static final RegExp _hslaRegExp = RegExp(r'(rgb|hsl)', caseSensitive: true);

  ///
  /// Returns a color from hsl, keeping the original color space
  ///
  @defineMethodSkip
  Color hslaColorSpace(Color origColor, HSLType hsl) {
    final color = hsla(hsl.h, hsl.s, hsl.l, hsl.a);
    if (color != null) {
      color.value =
          _hslaRegExp.hasMatch(origColor?.value ?? '') // todo could be null?
              ? origColor.value
              : 'rgb';
      return color;
    }
    return null;

// 3.8.0 20180729
//  function hsla(origColor, hsl) {
//      var color = colorFunctions.hsla(hsl.h, hsl.s, hsl.l, hsl.a);
//      if (color) {
//          if (origColor.value &&
//              /^(rgb|hsl)/.test(origColor.value)) {
//              color.value = origColor.value;
//          } else {
//              color.value = 'rgb';
//          }
//          return color;
//      }
//  }
  }

  ///
  /// Convert [color] to HSL or throw error
  ///
  @defineMethodSkip
  HSLType toHSL(Node color) => (color is Color)
      ? color.toHSL()
      : throw LessError(message: 'Argument cannot be evaluated to a color');

// 3.9.0 20190711
//  function toHSL(color) {
//    if (color.toHSL) {
//      return color.toHSL();
//    } else {
//      throw new Error('Argument cannot be evaluated to a color');
//    }
//  }

  ///
  /// Convert [color] to HSV or throw error
  ///
  @defineMethodSkip
  HSVType toHSV(Node color) => (color is Color)
      ? color.toHSV()
      : throw LessError(message: 'Argument cannot be evaluated to a color');

// 3.9.0 20190711
//  function toHSV(color) {
//    if (color.toHSV) {
//      return color.toHSV();
//    } else {
//      throw new Error('Argument cannot be evaluated to a color');
//    }
//  }

  ///
  /// [n] num | Node<Dimension> | error anything else
  ///
  @defineMethodSkip
  num number(dynamic n) {
    if (n is Dimension) {
      return n.unit.isUnit('%') ? n.value / 100 : n.value;
    } else if (n is num) {
      return n;
    } else {
      throw LessExceptionError(LessError(
          type: 'Argument',
          message: 'color functions take numbers as parameters'));
    }

//  function number(n) {
//      if (n instanceof Dimension) {
//          return parseFloat(n.unit.is('%') ? n.value / 100 : n.value);
//      } else if (typeof(n) === 'number') {
//          return n;
//      } else {
//          throw {
//              type: "Argument",
//              message: "color functions take numbers as parameters"
//          };
//      }
//  }
  }

  ///
  @defineMethodSkip
  num scaled(dynamic n, int size) {
    if (n is Dimension && n.unit.isUnit('%')) {
      return n.value * size / 100;
    } else {
      return number(n);
    }

//    function scaled(n, size) {
//        if (n instanceof Dimension && n.unit.is('%')) {
//            return parseFloat(n.value * size / 100);
//        } else {
//            return number(n);
//        }
//    }
  }

// ****************************************************************************

  ///
  /// Creates an opaque color object from decimal red, green and blue (RGB) values.
  /// Literal color values in standard HTML/CSS formats may also be used to define colors,
  /// for example #ff0000.
  ///
  /// Parameters:
  ///   red: An integer 0-255 or percentage 0-100%.
  ///   green: An integer 0-255 or percentage 0-100%.
  ///   blue: An integer 0-255 or percentage 0-100%.
  ///   Returns: color
  /// Example: rgb(90, 129, 32)
  ///   Output: #5a8120
  ///
  Color rgb(dynamic r, [dynamic g, dynamic b]) {
    final color = rgba(r, g, b, 1.0);
    color?.value = 'rgb';
    return color;

// 3.8.0 20180729
//  rgb: function (r, g, b) {
//      var color = colorFunctions.rgba(r, g, b, 1.0);
//      if (color) {
//          color.value = 'rgb';
//          return color;
//      }
//  },
  }

  ///
  /// Creates a transparent color object from decimal red, green, blue and alpha (RGBA) values.
  ///
  /// Parameters:
  ///   red: An integer 0-255 or percentage 0-100%.
  ///   green: An integer 0-255 or percentage 0-100%.
  ///   blue: An integer 0-255 or percentage 0-100%.
  ///   alpha: A number 0-1 or percentage 0-100%.
  ///   Returns: color
  /// Example: rgba(90, 129, 32, 0.5)
  ///   Output: rgba(90, 129, 32, 0.5)
  ///
  // r, g, b, a are (Dimension | num). r could be Color.
  Color rgba(dynamic r, [dynamic g, dynamic b, dynamic a]) {
    try {
      if (r is Color) {
        final alpha = g != null ? number(g) : r.alpha;
        return Color.fromList(r.rgb, alpha, 'rgba');
      }

      final rgb =
          <dynamic>[r, g, b].map((dynamic c) => scaled(c, 255)).toList();
      return Color.fromList(rgb, number(a), 'rgba');
    } catch (e) {
      return null;
    }

// 3.8.0 20180729
//  rgba: function (r, g, b, a) {
//      try {
//          if (r instanceof Color) {
//              if (g) {
//                  a = number(g);
//              } else {
//                  a = r.alpha;
//              }
//              return new Color(r.rgb, a, 'rgba');
//          }
//          var rgb = [r, g, b].map(function (c) { return scaled(c, 255); });
//          a = number(a);
//          return new Color(rgb, a, 'rgba');
//      }
//      catch (e) {}
//  },
  }

  ///
  /// Creates an opaque color object from hue, saturation and lightness (HSL) values.
  ///
  /// Parameters:
  ///   hue: An integer 0-360 representing degrees.
  ///   saturation: A percentage 0-100% or number 0-1.
  ///   lightness: A percentage 0-100% or number 0-1.
  ///   Returns: color
  /// Example: hsl(90, 100%, 50%)
  ///   Output: #80ff00
  ///
  Color hsl(dynamic h, [dynamic s, dynamic l]) {
    final color = hsla(h, s, l, 1.0);
    color?.value = 'hsl';
    return color;

// 3.8.0 20180729
//  hsl: function (h, s, l) {
//      var color = colorFunctions.hsla(h, s, l, 1.0);
//      if (color) {
//          color.value = 'hsl';
//          return color;
//      }
//  },
  }

  ///
  /// Creates a transparent color object from hue, saturation, lightness and alpha (HSLA) values.
  ///
  /// Parameters:
  ///   hue: An integer 0-360 representing degrees.
  ///   saturation: A percentage 0-100% or number 0-1.
  ///   lightness: A percentage 0-100% or number 0-1.
  ///   alpha: A percentage 0-100% or number 0-1.
  ///   Returns: color
  /// Example: hsl(90, 100%, 50%, 0.5)
  ///   Output: rgba(128, 255, 0, 0.5)
  ///
  Color hsla(dynamic h, [dynamic s, dynamic l, dynamic a]) {
    try {
      if (h is Color) {
        final alpha = s != null ? number(s) : h.alpha;
        return Color.fromList(h.rgb, alpha, 'hsla');
      }

      final dynamic _h = (number(h) % 360) / 360;
      final dynamic _s = clamp(number(s));
      final dynamic _l = clamp(number(l));
      final dynamic _a = clamp(number(a));

      final double m2 = (_l <= 0.5) ? _l * (_s + 1) : _l + _s - _l * _s;
      final double m1 = _l * 2 - m2;

      double hue(num h) {
        final _h = h < 0 ? h + 1 : (h > 1 ? h - 1 : h);
        if (_h * 6 < 1) {
          return m1 + (m2 - m1) * _h * 6;
        } else if (_h * 2 < 1) {
          return m2;
        } else if (_h * 3 < 2) {
          return m1 + (m2 - m1) * (2 / 3 - _h) * 6;
        } else {
          return m1;
        }
      }

      final rgb = <num>[
        hue(_h + 1 / 3) * 255,
        hue(_h) * 255,
        hue(_h - 1 / 3) * 255
      ];
      return Color.fromList(rgb, _a, 'hsla');
    } catch (e) {
      return null;
    }

// 3.8.0 20180729
//  hsla: function (h, s, l, a) {
//      try {
//          if (h instanceof Color) {
//              if (s) {
//                  a = number(s);
//              } else {
//                  a = h.alpha;
//              }
//              return new Color(h.rgb, a, 'hsla');
//          }
//
//          var m1, m2;
//
//          function hue(h) {
//              h = h < 0 ? h + 1 : (h > 1 ? h - 1 : h);
//              if (h * 6 < 1) {
//                  return m1 + (m2 - m1) * h * 6;
//              }
//              else if (h * 2 < 1) {
//                  return m2;
//              }
//              else if (h * 3 < 2) {
//                  return m1 + (m2 - m1) * (2 / 3 - h) * 6;
//              }
//              else {
//                  return m1;
//              }
//          }
//
//          h = (number(h) % 360) / 360;
//          s = clamp(number(s)); l = clamp(number(l)); a = clamp(number(a));
//
//          m2 = l <= 0.5 ? l * (s + 1) : l + s - l * s;
//          m1 = l * 2 - m2;
//
//          var rgb = [
//              hue(h + 1 / 3) * 255,
//              hue(h)       * 255,
//              hue(h - 1 / 3) * 255
//          ];
//          a = number(a);
//          return new Color(rgb, a, 'hsla');
//      }
//      catch (e) {}
//  },

//    hsla: function (h, s, l, a) {
//        function hue(h) {
//            h = h < 0 ? h + 1 : (h > 1 ? h - 1 : h);
//            if      (h * 6 < 1) { return m1 + (m2 - m1) * h * 6; }
//            else if (h * 2 < 1) { return m2; }
//            else if (h * 3 < 2) { return m1 + (m2 - m1) * (2/3 - h) * 6; }
//            else                { return m1; }
//        }
//
//        h = (number(h) % 360) / 360;
//        s = clamp(number(s)); l = clamp(number(l)); a = clamp(number(a));
//
//        var m2 = l <= 0.5 ? l * (s + 1) : l + s - l * s;
//        var m1 = l * 2 - m2;
//
//        return colorFunctions.rgba(hue(h + 1/3) * 255,
//            hue(h)       * 255,
//            hue(h - 1/3) * 255,
//            a);
//    }
  }

  ///
  /// Creates an opaque color object from hue, saturation and value (HSV) values.
  /// Note that this is a color space available in Photoshop, and is not the same as hsl.
  ///
  /// Parameters:
  ///   hue: An integer 0-360 representing degrees.
  ///   saturation: A percentage 0-100% or number 0-1.
  ///   value: A percentage 0-100% or number 0-1.
  ///   Returns: color
  /// Example: hsv(90, 100%, 50%)
  ///   Output: #408000
  ///
  Color hsv(dynamic h, dynamic s, dynamic v) => hsva(h, s, v, 1.0);

  ///
  /// Creates a transparent color object from hue, saturation, value and alpha (HSVA) values.
  /// Note that this is not the same as hsla, and is a color space available in Photoshop.
  ///
  /// Parameters:
  ///   hue: An integer 0-360 representing degrees.
  ///   saturation: A percentage 0-100% or number 0-1.
  ///   value: A percentage 0-100% or number 0-1.
  ///   alpha: A percentage 0-100% or number 0-1.
  ///   Returns: color
  /// Example: hsva(90, 100%, 50%, 0.5)
  ///   Output: rgba(64, 128, 0, 0.5)
  ///
  Color hsva(dynamic h, dynamic s, dynamic v, dynamic a) {
    final dynamic _h = ((number(h) % 360) / 360) * 360;
    final dynamic _s = number(s);
    final dynamic _v = number(v);
    final dynamic _a = number(a);

    final int i = ((_h / 60) % 6).floor();
    final double f = (_h / 60) - i;

    final vs = <num>[
      _v,
      _v * (1 - _s),
      _v * (1 - f * _s),
      _v * (1 - (1 - f) * _s)
    ];

    final perm = <List<int>>[
      <int>[0, 3, 1],
      <int>[2, 0, 1],
      <int>[1, 0, 3],
      <int>[1, 2, 0],
      <int>[3, 1, 0],
      <int>[0, 1, 2]
    ];

    return rgba(
        vs[perm[i][0]] * 255, vs[perm[i][1]] * 255, vs[perm[i][2]] * 255, _a);

//    hsva: function(h, s, v, a) {
//        h = ((number(h) % 360) / 360) * 360;
//        s = number(s); v = number(v); a = number(a);
//
//        var i, f;
//        i = Math.floor((h / 60) % 6);
//        f = (h / 60) - i;
//
//        var vs = [v,
//            v * (1 - s),
//            v * (1 - f * s),
//            v * (1 - (1 - f) * s)];
//        var perm = [[0, 3, 1],
//            [2, 0, 1],
//            [1, 0, 3],
//            [1, 2, 0],
//            [3, 1, 0],
//            [0, 1, 2]];
//
//        return colorFunctions.rgba(vs[perm[i][0]] * 255,
//            vs[perm[i][1]] * 255,
//            vs[perm[i][2]] * 255,
//            a);
//    }
  }

  ///
  /// Extracts the hue channel of a color object in the HSL color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-360
  /// Example: hue(hsl(90, 100%, 50%))
  ///   Output: 90
  ///
  Dimension hue(Node color) => Dimension(toHSL(color).h);

// 3.9.0 20190711
//  hue: function (color) {
//    return new Dimension(toHSL(color).h);
//  },

  ///
  /// Extracts the saturation channel of a color object in the HSL color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: saturation(hsl(90, 100%, 50%))
  ///   Output: 100%
  ///
  Dimension saturation(Node color) => Dimension(toHSL(color).s * 100, '%');

// 3.9.0 20190711
//  saturation: function (color) {
//    return new Dimension(toHSL(color).s * 100, '%');
//  },

  ///
  /// Extracts the lightness channel of a color object in the HSL color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: lightness(hsl(90, 100%, 50%))
  ///   Output: 50%
  ///
  Dimension lightness(Node color) => Dimension(toHSL(color).l * 100, '%');

// 3.9.0 20190711
//  lightness: function (color) {
//    return new Dimension(toHSL(color).l * 100, '%');
//  },

  ///
  /// Extracts the hue channel of a color object in the HSV color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-360
  /// Example: hsvhue(hsv(90, 100%, 50%))
  ///   Output: 90
  ///
  Dimension hsvhue(Node color) => Dimension(toHSV(color).h);

// 3.9.0 20190711
//  hsvhue: function(color) {
//    return new Dimension(toHSV(color).h);
//  },

  ///
  /// Extracts the saturation channel of a color object in the HSV color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: hsvsaturation(hsv(90, 100%, 50%))
  ///   Output: 100%
  ///
  Dimension hsvsaturation(Node color) => Dimension(toHSV(color).s * 100, '%');

// 3.9.0 20190711
//  hsvsaturation: function (color) {
//    return new Dimension(toHSV(color).s * 100, '%');
//  },

  ///
  /// Extracts the value channel of a color object in the HSV color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: hsvvalue(hsv(90, 100%, 50%))
  ///   Output: 50%
  ///
  Dimension hsvvalue(Node color) => Dimension(toHSV(color).v * 100, '%');

// 3.9.0 20190711
//  hsvvalue: function (color) {
//    return new Dimension(toHSV(color).v * 100, '%');
//  },

  ///
  /// Extracts the red channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-255
  /// Example: red(rgb(10, 20, 30))
  ///   Output: 10
  //
  Dimension red(Color color) => Dimension(color.r);

  ///
  /// Extracts the green channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-255
  /// Example: green(rgb(10, 20, 30))
  ///   Output: 20
  ///
  Dimension green(Color color) => Dimension(color.g);

  ///
  /// Extracts the blue channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-255
  /// Example: blue(rgb(10, 20, 30))
  ///   Output: 30
  ///
  Dimension blue(Color color) => Dimension(color.b);

  ///
  /// Extracts the alpha channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: float 0-1
  /// Example: alpha(rgba(10, 20, 30, 0.5))
  ///   Output: 0.5
  ///
  Dimension alpha(Node color) => Dimension(toHSL(color).a); //color.alpha?

// 3.9.0 20190711
//  alpha: function (color) {
//    return new Dimension(toHSL(color).a);
//  },

  ///
  /// Calculates the luma (perceptual brightness) of a color object.
  //
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100%
  /// Example: luma(rgb(100, 200, 30))
  ///   Output: 44%
  ///
  Dimension luma(Color color) =>
      Dimension(color.luma() * color.alpha * 100, '%');

  ///
  /// Calculates the value of the luma without gamma correction
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100%
  /// Example: luminance(rgb(100, 200, 30))
  ///   Output: 65%
  ///
  Dimension luminance(Color color) {
    final luminance = (0.2126 * color.r / 255) +
        (0.7152 * color.g / 255) +
        (0.0722 * color.b / 255);

    return Dimension(luminance * color.alpha * 100, '%');

//    luminance: function (color) {
//        var luminance =
//            (0.2126 * color.rgb[0] / 255)
//                + (0.7152 * color.rgb[1] / 255)
//                + (0.0722 * color.rgb[2] / 255);
//
//        return new Dimension(luminance * color.alpha * 100, '%');
//    }
  }

  ///
  /// Increase the saturation of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   method: Optional, set to relative for the adjustment to be relative to the current value.
  ///   Returns: color
  /// Example: saturate(hsl(90, 80%, 50%), 20%)
  ///   Output: #80ff00 // hsl(90, 100%, 50%)
  ///
  Color saturate(Node color, [Dimension amount, Keyword method]) {
    // filter: saturate(3.2);
    // should be kept as is, so check for color
    if (color is! Color) return null; // ??

    final hsl = toHSL(color);

    hsl
      ..s += (method?.value == 'relative')
          ? hsl.s * amount.value / 100
          : amount.value / 100
      ..s = clamp(hsl.s);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  saturate: function (color, amount, method) {
//    // filter: saturate(3.2);
//    // should be kept as is, so check for color
//    if (!color.rgb) {
//      return null;
//    }
//    var hsl = toHSL(color);
//
//    if (typeof method !== 'undefined' && method.value === 'relative') {
//      hsl.s +=  hsl.s * amount.value / 100;
//    }
//    else {
//      hsl.s += amount.value / 100;
//    }
//    hsl.s = clamp(hsl.s);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Decrease the saturation of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   method: Optional, set to relative for the adjustment to be relative to the current value.
  ///   Returns: color
  /// Example: desaturate(hsl(90, 80%, 50%), 20%)
  ///   Output: #80cc33 // hsl(90, 60%, 50%)
  ///
  Color desaturate(Node color, Dimension amount, [Keyword method]) {
    final hsl = toHSL(color);

    hsl
      ..s -= (method?.value == 'relative')
          ? hsl.s * amount.value / 100
          : amount.value / 100
      ..s = clamp(hsl.s);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  desaturate: function (color, amount, method) {
//    var hsl = toHSL(color);
//
//    if (typeof method !== 'undefined' && method.value === 'relative') {
//      hsl.s -=  hsl.s * amount.value / 100;
//    }
//    else {
//      hsl.s -= amount.value / 100;
//    }
//    hsl.s = clamp(hsl.s);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Increase the lightness of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   method: Optional, set to relative for the adjustment to be relative to the current value.
  ///   Returns: color
  /// Example: lighten(hsl(90, 80%, 50%), 20%)
  ///   Output: #b3f075 // hsl(90, 80%, 70%)
  ///
  Color lighten(Node color, Dimension amount, [Keyword method]) {
    final hsl = toHSL(color);

    hsl
      ..l += (method?.value == 'relative')
          ? hsl.l * amount.value / 100
          : amount.value / 100
      ..l = clamp(hsl.l);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  lighten: function (color, amount, method) {
//    var hsl = toHSL(color);
//
//    if (typeof method !== 'undefined' && method.value === 'relative') {
//      hsl.l +=  hsl.l * amount.value / 100;
//    }
//    else {
//      hsl.l += amount.value / 100;
//    }
//    hsl.l = clamp(hsl.l);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Decrease the lightness of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   method: Optional, set to relative for the adjustment to be relative to the current value.
  ///   Returns: color
  /// Example: darken(hsl(90, 80%, 50%), 20%)
  ///   Output: #4d8a0f // hsl(90, 80%, 30%)
  ///
  Color darken(Node color, Dimension amount, [Keyword method]) {
    final hsl = toHSL(color);

    hsl
      ..l -= (method?.value == 'relative')
          ? hsl.l * amount.value / 100
          : amount.value / 100
      ..l = clamp(hsl.l);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  darken: function (color, amount, method) {
//    var hsl = toHSL(color);
//
//    if (typeof method !== 'undefined' && method.value === 'relative') {
//      hsl.l -=  hsl.l * amount.value / 100;
//    }
//    else {
//      hsl.l -= amount.value / 100;
//    }
//    hsl.l = clamp(hsl.l);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Decrease the transparency (or increase the opacity) of a color, making it more opaque.
  //
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   method: Optional, set to relative for the adjustment to be relative to the current value.
  ///   Returns: color
  /// Example: fadein(hsla(90, 90%, 50%, 0.5), 10%)
  ///   Output: rgba(128, 242, 13, 0.6) // hsla(90, 90%, 50%, 0.6)
  ///
  Color fadein(Node color, Dimension amount, [Keyword method]) {
    final hsl = toHSL(color);

    hsl
      ..a += (method?.value == 'relative')
          ? hsl.a * amount.value / 100
          : amount.value / 100
      ..a = clamp(hsl.a);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  fadein: function (color, amount, method) {
//    var hsl = toHSL(color);
//
//    if (typeof method !== 'undefined' && method.value === 'relative') {
//      hsl.a +=  hsl.a * amount.value / 100;
//    }
//    else {
//      hsl.a += amount.value / 100;
//    }
//    hsl.a = clamp(hsl.a);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Increase the transparency (or decrease the opacity) of a color, making it less opaque.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   method: Optional, set to relative for the adjustment to be relative to the current value.
  ///   Returns: color
  /// Example: fadeout(hsla(90, 90%, 50%, 0.5), 10%)
  ///   Output: rgba(128, 242, 13, 0.4) // hsla(90, 90%, 50%, 0.4)
  ///
  Color fadeout(Node color, Dimension amount, [Keyword method]) {
    final hsl = toHSL(color);

    hsl
      ..a -= (method?.value == 'relative')
          ? hsl.a * amount.value / 100
          : amount.value / 100
      ..a = clamp(hsl.a);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  fadeout: function (color, amount, method) {
//    var hsl = toHSL(color);
//
//    if (typeof method !== 'undefined' && method.value === 'relative') {
//      hsl.a -=  hsl.a * amount.value / 100;
//    }
//    else {
//      hsl.a -= amount.value / 100;
//    }
//    hsl.a = clamp(hsl.a);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Set the absolute transparency of a color.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: fade(hsl(90, 90%, 50%), 10%)
  ///   Output: rgba(128, 242, 13, 0.1) //hsla(90, 90%, 50%, 0.1)
  ///
  Color fade(Node color, Dimension amount) {
    final hsl = toHSL(color);

    hsl
      ..a = amount.value / 100
      ..a = clamp(hsl.a);

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  fade: function (color, amount) {
//    var hsl = toHSL(color);
//
//    hsl.a = amount.value / 100;
//    hsl.a = clamp(hsl.a);
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Rotate the hue angle of a color in either direction. While the angle range
  /// is 0-360, it applies a mod 360 operation, so you can pass in much larger
  /// (or negative) values and they will wrap around angles of 360 and 720 will
  /// produce the same result. Note that colors are passed through an RGB
  /// conversion, which doesn't retain hue value for greys (because hue has no
  /// meaning when there is no saturation), so make sure you apply functions in
  /// a way that preserves hue, for example don't do this:
  ///
  /// @c: saturate(spin(#aaaaaa, 10), 10%);
  ///
  /// Do this instead:
  /// @c: spin(saturate(#aaaaaa, 10%), 10);
  ///
  /// Colors are always returned as RGB values, so applying spin to a grey value
  /// will do nothing.
  //
  /// Parameters:
  ///   color: A color object.
  ///   angle: A number of degrees to rotate (+ or -).
  ///   Returns: color
  /// Example:
  ///   spin(hsl(10, 90%, 50%), 30)
  ///   spin(hsl(10, 90%, 50%), -30)
  ///   Output:
  ///     #f2a60d // hsl(40, 90%, 50%)
  ///     #f20d59 // hsl(340, 90%, 50%)
  ///
  Color spin(Node color, Dimension amount) {
    final hsl = toHSL(color);
    final hue = (hsl.h + amount.value) % 360;

    hsl.h = hue < 0 ? 360 + hue : hue;

    return hslaColorSpace(color, hsl);

// 3.9.0 20190711
//  spin: function (color, amount) {
//    var hsl = toHSL(color);
//    var hue = (hsl.h + amount.value) % 360;
//
//    hsl.h = hue < 0 ? 360 + hue : hue;
//
//    return hsla(color, hsl);
//  },
  }

  ///
  /// Mix two colors together in variable proportion. Opacity is included in the calculations.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   weight: Optional, a percentage balance point between the two colors, defaults to 50%.
  ///   Returns: color
  /// Example:
  ///   mix(#ff0000, #0000ff, 50%)
  ///   mix(rgba(100,0,0,1.0), rgba(0,100,0,0.5), 50%)
  ///   Output:
  ///     #800080
  ///     rgba(75, 25, 0, 0.75)
  ///
  // Copyright (c) 2006-2009 Hampton Catlin, Natalie Weizenbaum, and Chris Eppstein
  // http://sass-lang.com
  Color mix(Node color1, Node color2, [Dimension weight]) {
    weight ??= Dimension(50);

    final p = weight.value / 100.0;
    final w = p * 2 - 1;
    final a = toHSL(color1).a - toHSL(color2).a;

    // we are sure now color1 and color2 are Color type
    final Color _color1 = color1;
    final Color _color2 = color2;

    final w1 = (((w * a == -1) ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
    final w2 = 1 - w1;

    final rgb = <num>[
      _color1.r * w1 + _color2.r * w2,
      _color1.g * w1 + _color2.g * w2,
      _color1.b * w1 + _color2.b * w2
    ];

    final double alpha = _color1.alpha * p + _color2.alpha * (1 - p);

    return Color.fromList(rgb, alpha);

// 3.9.0 20190711
//  mix: function (color1, color2, weight) {
//    if (!weight) {
//      weight = new Dimension(50);
//    }
//    var p = weight.value / 100.0;
//    var w = p * 2 - 1;
//    var a = toHSL(color1).a - toHSL(color2).a;
//
//    var w1 = (((w * a == -1) ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
//    var w2 = 1 - w1;
//
//    var rgb = [color1.rgb[0] * w1 + color2.rgb[0] * w2,
//      color1.rgb[1] * w1 + color2.rgb[1] * w2,
//      color1.rgb[2] * w1 + color2.rgb[2] * w2];
//
//    var alpha = color1.alpha * p + color2.alpha * (1 - p);
//
//    return new Color(rgb, alpha);
//  },
  }

  ///
  /// Remove all saturation from a color in the HSL color space; the same as
  /// calling desaturate(@color, 100%).
  //
  /// Parameters:
  ///   color: A color object.
  ///   Returns: color
  /// Example: greyscale(hsl(90, 90%, 50%))
  ///   Output: #808080 // hsl(90, 0%, 50%)
  ///
  Color greyscale(Color color) => desaturate(color, Dimension(100));

  ///
  /// Choose which of two colors provides the greatest contrast with another.
  ///
  /// Parameters:
  ///   color: A color object to compare against.
  ///   dark: optional - A designated dark color (defaults to black).
  ///   light: optional - A designated light color (defaults to white).
  ///   threshold: optional - A percentage 0-100% specifying where the
  ///   transition from "dark" to "light" is (defaults to 43%, matching SASS).
  ///   Returns: color
  ///
  Color contrast(Node colorNode,
      [Color dark, Color light, Dimension threshold]) {
    // filter: contrast(3.2);
    // should be kept as is, so check for color
    if (colorNode is! Color) return null;
    final Color color = colorNode;

    var _light = light ?? rgba(255, 255, 255, 1.0);
    var _dark = dark ?? rgba(0, 0, 0, 1.0);

    //Figure out which is actually light and dark!
    if (_dark.luma() > _light.luma()) {
      final t = _light;
      _light = _dark;
      _dark = t;
    }

    final double _threshold = (threshold == null) ? 0.43 : number(threshold);
    return (color.luma() < _threshold) ? _light : _dark;

//    contrast: function (color, dark, light, threshold) {
//        // filter: contrast(3.2);
//        // should be kept as is, so check for color
//        if (!color.rgb) {
//            return null;
//        }
//        if (typeof light === 'undefined') {
//            light = colorFunctions.rgba(255, 255, 255, 1.0);
//        }
//        if (typeof dark === 'undefined') {
//            dark = colorFunctions.rgba(0, 0, 0, 1.0);
//        }
//        //Figure out which is actually light and dark!
//        if (dark.luma() > light.luma()) {
//            var t = light;
//            light = dark;
//            dark = t;
//        }
//        if (typeof threshold === 'undefined') {
//            threshold = 0.43;
//        } else {
//            threshold = number(threshold);
//        }
//        if (color.luma() < threshold) {
//            return light;
//        } else {
//            return dark;
//        }
//    }
  }

  ///
  /// Creates a hex representation of a color in #AARRGGBB format (NOT #RRGGBBAA!).
  /// This format is used in Internet Explorer, and .NET and Android development.
  ///
  /// Parameters:
  ///   color, color object.
  ///   Returns: string
  /// Example: argb(rgba(90, 23, 148, 0.5));
  ///   Output: #805a1794
  ///
  Anonymous argb(Color color) => Anonymous(color.toARGB())..parsed = true;

  ///
  /// Parses a color, so a string representing a color becomes a color.
  ///
  /// Parameters:
  ///   string: a string of the specified color.
  ///   Returns: color
  /// Example:
  ///   color("#aaa");
  ///   Output: #aaa
  ///
  Color color(dynamic c) {
    final re = RegExp(r'^#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3,4})$',
        caseSensitive: false);

    if (c is Quoted && re.hasMatch(c.value)) {
      final val = c.value.substring(1);
      return Color(val, null, '#$val');
    }

    final _c = (c is Color)
        ? c
        : Color.fromKeyword(c.value); //c.value must be a color name
    if (_c != null) {
      _c.value = null;
      return _c;
    }
    throw LessExceptionError(LessError(
        type: 'Argument',
        message:
            'argument must be a color keyword or 3|4|6|8 digit hex e.g. #FFF'));

// 3.8.0 20180729
//  color: function(c) {
//      if ((c instanceof Quoted) &&
//          (/^#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3,4})$/i.test(c.value))) {
//          var val = c.value.slice(1);
//          return new Color(val, undefined, '#' + val);
//      }
//      if ((c instanceof Color) || (c = Color.fromKeyword(c.value))) {
//          c.value = undefined;
//          return c;
//      }
//      throw {
//          type:    'Argument',
//          message: 'argument must be a color keyword or 3|4|6|8 digit hex e.g. #FFF'
//      };
//  },
  }

  ///
  /// returns a [color] [amount]% points *lighter*
  ///
  Color tint(Color color, Dimension amount) =>
      mix(rgb(255, 255, 255), color, amount);

  ///
  /// returns a [color] [amount]% points *darker*
  ///
  Color shade(Color color, Dimension amount) =>
      mix(rgb(0, 0, 0), color, amount);
}
