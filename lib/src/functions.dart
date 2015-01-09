// source: less/functions.js 1.7.5

library functions.less;

import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;

import 'env.dart';
import 'file_info.dart';
import 'less_error.dart';
import 'nodejs/nodejs.dart';
import 'tree/tree.dart';

class Functions {
  ColorBlend colorBlend;
  FileInfo currentFileInfo;
  Env env;

  /// Methods description: name, {f: function, args: num arguments}
  /// If num arguments is -1 then pass all arguments in list
  Map<String, Object> methods;

  Functions() {
    this.methods = {
      'rgb':        {'f': rgb,'args': 3},
      'rgba':       {'f': rgba, 'args': 4},
      'hsl':        {'f': hsl, 'args': 3},
      'hsla':       {'f': hsla, 'args': 4},
      'hsv':        {'f': hsv, 'args': 3},
      'hsva':       {'f': hsva, 'args': 4},
      'hue':        {'f': hue, 'args': 1},
      'saturation': {'f': saturation, 'args': 1},
      'lightness':  {'f': lightness, 'args': 1},
      'hsvhue':     {'f': hsvhue, 'args': 1},
      'hsvsaturation': {'f': hsvsaturation, 'args': 1},
      'hsvvalue':   {'f': hsvvalue, 'args': 1},
      'red':        {'f': red, 'args': 1},
      'green':      {'f': green, 'args': 1},
      'blue':       {'f': blue, 'args': 1},
      'alpha':      {'f': alpha, 'args': 1},
      'luma':       {'f': luma, 'args': 1},
      'luminance':  {'f': luminance, 'args': 1},
      'saturate':   {'f': saturate, 'args': 2 },
      'desaturate': {'f': desaturate, 'args': 2 },
      'lighten':    {'f': lighten, 'args': 2 },
      'darken':     {'f': darken, 'args': 2 },
      'fadein':     {'f': fadein, 'args': 2 },
      'fadeout':    {'f': fadeout, 'args': 2 },
      'fade':       {'f': fade, 'args': 2 },
      'spin':       {'f': spin, 'args': 2 },
      'mix':        {'f': mix, 'args': 3 }, // 2 to 3 args
      'greyscale':  {'f': greyscale, 'args': 1 },
      'contrast':   {'f': contrast, 'args': 4 }, // 1 to 4 args
      'multiply':   {'f': multiply, 'args': 2}, // ColorBlend start
      'screen':     {'f': screen, 'args': 2},
      'overlay':    {'f': overlay, 'args': 2},
      'softlight':  {'f': softlight, 'args': 2},
      'hardlight':  {'f': hardlight, 'args': 2},
      'difference': {'f': difference, 'args': 2},
      'exclusion':  {'f': exclusion, 'args': 2},
      'average':    {'f': average, 'args': 2},
      'negation':   {'f': negation, 'args': 2}, // // ColorBlend end
      'e':          {'f': e, 'args': 1 },
      'escape':     {'f': escape, 'args': 1 },
      'replace':    {'f': replace, 'args': 4 },
      '%':          {'f': format, 'args': -1 },
      'unit':       {'f': unit, 'args': 2 },
      'convert':    {'f': convert, 'args': 2 },
      'round':      {'f': round, 'args': 2 },
      'pi':         {'f': pi, 'args': 0 },
      'mod':        {'f': mod, 'args': 2 },
      'pow':        {'f': pow, 'args': 2 },
      'min':        {'f': min, 'args': -1 },
      'max':        {'f': max, 'args': -1 },
      'get-unit':   {'f': getUnit, 'args': 1},
      'argb':       {'f': argb, 'args': 1 },
      'percentage': {'f': percentage, 'args': 1 },
      'color':      {'f': color, 'args': 1 },
      'iscolor':    {'f': iscolor, 'args': 1 },
      'isnumber':   {'f': isnumber, 'args': 1 },
      'isstring':   {'f': isstring, 'args': 1 },
      'iskeyword':  {'f': iskeyword, 'args': 1 },
      'isurl':      {'f': isurl, 'args': 1 },
      'ispixel':    {'f': ispixel, 'args': 1 },
      'ispercentage': {'f': ispercentage, 'args': 1 },
      'isem':       {'f': isem, 'args': 1 },
      'isunit':     {'f': isunit, 'args': 2 },
      'tint':       {'f': tint, 'args': 2 },
      'shade':      {'f': shade, 'args': 2 },
      'extract':    {'f': extract, 'args': 2 },
      'length':     {'f': length, 'args': 1 },
      'data-uri':   {'f': dataURI, 'args': 2 },
      'svg-gradient': {'f': svgGradient, 'args': -1 },
      'ceil':       {'f': ceil, 'args': 1 },
      'floor':      {'f': floor, 'args': 1 },
      'sqrt':       {'f': sqrt, 'args': 1 },
      'abs':        {'f': abs, 'args': 1 },
      'tan':        {'f': tan, 'args': 1 },
      'sin':        {'f': sin, 'args': 1 },
      'cos':        {'f': cos, 'args': 1 },
      'atan':       {'f': atan, 'args': 1 },
      'asin':       {'f': asin, 'args': 1 },
      'acos':       {'f': acos, 'args': 1 }
    };

    this.colorBlend = new ColorBlend();
  }

  /// [method] is a Function method
  bool isMethod(String method) => methods.containsKey(method);

  /// Execute method(arguments)
  call(String method, List arguments) {
    var fun = methods[method];
    if (fun == null) return null;
    int argsLength = arguments.length;
    if (fun['args'] == -1) argsLength = -1;

    switch (argsLength) {
      case -1:
        return fun['f'](arguments);
      case 0:
        return fun['f']();
      case 1:
        return fun['f'](arguments[0]);
      case 2:
        return fun['f'](arguments[0], arguments[1]);
      case 3:
        return fun['f'](arguments[0], arguments[1], arguments[2]);
      case 4:
        return fun['f'](arguments[0], arguments[1], arguments[2], arguments[3]);
      default:
        return null;
    }
  }


  //--------- Color Blend ----------------------------

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
  Color rgb(r, g, b) => this.rgba(r, g, b, 1.0);

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
  Color rgba(r, g, b, a) {
    List<int> rgb = [r, g, b].map((c) => scaled(c, 255)).toList();
    a = number(a);
    return new Color(rgb, a);

//    rgba: function (r, g, b, a) {
//        var rgb = [r, g, b].map(function (c) { return scaled(c, 255); });
//        a = number(a);
//        return new(tree.Color)(rgb, a);
//    },
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
  Color hsl(h, s, l) => this.hsla(h, s, l, 1.0);

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
  Color hsla(h, s, l, a) {
    double m1;
    double m2;

    hue(h) {
      h = h < 0 ? h + 1 : (h > 1 ? h - 1 : h);
      if (h * 6 < 1) {
        return m1 + (m2 - m1) * h * 6;
      } else if (h * 2 < 1) {
        return m2;
      } else if (h * 3 < 2) {
        return m1 + (m2 - m1) * (2 / 3 - h) * 6;
      } else {
        return m1;
      }
    }

    h = (number(h) % 360) / 360;
    s = clamp(number(s));
    l = clamp(number(l));
    a = clamp(number(a));

    m2 = l <= 0.5 ? l * (s + 1) : l + s - l * s;
    m1 = l * 2 - m2;

    return this.rgba(
        hue(h + 1 / 3) * 255,
        hue(h) * 255,
        hue(h - 1 / 3) * 255,
        a);

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
//        return this.rgba(hue(h + 1/3) * 255,
//                         hue(h)       * 255,
//                         hue(h - 1/3) * 255,
//                         a);
//    },
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
  Color hsv(h, s, v) => this.hsva(h, s, v, 1.0);

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
  Color hsva(h, s, v, a) {
    h = ((number(h) % 360) / 360) * 360;
    s = number(s);
    v = number(v);
    a = number(a);

    int i = ((h / 60) % 6).floor();
    double f = (h / 60) - i;

    List vs = [v,
               v * (1 - s),
               v * (1 - f * s),
               v * (1 - (1 - f) * s)];
    List perm = [
        [0, 3, 1],
        [2, 0, 1],
        [1, 0, 3],
        [1, 2, 0],
        [3, 1, 0],
        [0, 1, 2]];

    return this.rgba(
        vs[perm[i][0]] * 255,
        vs[perm[i][1]] * 255,
        vs[perm[i][2]] * 255,
        a);

//    hsva: function(h, s, v, a) {
//        h = ((number(h) % 360) / 360) * 360;
//        s = number(s); v = number(v); a = number(a);
//
//        var i, f;
//        i = Math.floor((h / 60) % 6);
//        f = (h / 60) - i;
//
//        var vs = [v,
//                  v * (1 - s),
//                  v * (1 - f * s),
//                  v * (1 - (1 - f) * s)];
//        var perm = [[0, 3, 1],
//                    [2, 0, 1],
//                    [1, 0, 3],
//                    [1, 2, 0],
//                    [3, 1, 0],
//                    [0, 1, 2]];
//
//        return this.rgba(vs[perm[i][0]] * 255,
//                         vs[perm[i][1]] * 255,
//                         vs[perm[i][2]] * 255,
//                         a);
//    },
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
  Dimension hue(Color color) => new Dimension(color.toHSL().h);

  ///
  /// Extracts the saturation channel of a color object in the HSL color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: saturation(hsl(90, 100%, 50%))
  ///   Output: 100%
  ///
  Dimension saturation(Color color) => new Dimension(color.toHSL().s * 100, '%');

  ///
  /// Extracts the lightness channel of a color object in the HSL color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: lightness(hsl(90, 100%, 50%))
  ///   Output: 50%
  ///
  Dimension lightness(Color color) => new Dimension(color.toHSL().l * 100, '%');

  ///
  /// Extracts the hue channel of a color object in the HSV color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-360
  /// Example: hsvhue(hsv(90, 100%, 50%))
  ///   Output: 90
  ///
  Dimension hsvhue(Color color) => new Dimension(color.toHSV().h);

  ///
  /// Extracts the saturation channel of a color object in the HSV color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: hsvsaturation(hsv(90, 100%, 50%))
  ///   Output: 100%
  ///
  Dimension hsvsaturation(Color color) => new Dimension(color.toHSV().s * 100, '%');

  ///
  /// Extracts the value channel of a color object in the HSV color space.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100
  /// Example: hsvvalue(hsv(90, 100%, 50%))
  ///   Output: 50%
  ///
  Dimension hsvvalue(Color color) => new Dimension(color.toHSV().v * 100, '%');

  ///
  /// Extracts the red channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-255
  /// Example: red(rgb(10, 20, 30))
  ///   Output: 10
  ///
  Dimension red(Color color) => new Dimension(color.r);

  ///
  /// Extracts the green channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-255
  /// Example: green(rgb(10, 20, 30))
  ///   Output: 20
  ///
  Dimension green(Color color) => new Dimension(color.g);

  ///
  /// Extracts the blue channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: integer 0-255
  /// Example: blue(rgb(10, 20, 30))
  ///   Output: 30
  ///
  Dimension blue(Color color) => new Dimension(color.b);

  ///
  /// Extracts the alpha channel of a color object.
  ///
  /// Parameters:
  ///   color - a color object.
  ///   Returns: float 0-1
  /// Example: alpha(rgba(10, 20, 30, 0.5))
  ///   Output: 0.5
  ///
  Dimension alpha(Color color) => new Dimension(color.toHSL().a); //color.alpha?

  ///
  /// Calculates the luma (perceptual brightness) of a color object.
  //
  /// Parameters:
  ///   color - a color object.
  ///   Returns: percentage 0-100%
  /// Example: luma(rgb(100, 200, 30))
  ///   Output: 44%
  ///
  Dimension luma(Color color) => new Dimension(color.luma() * color.alpha * 100, '%');

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
    double luminance =
              (0.2126 * color.r / 255)
            + (0.7152 * color.g / 255)
            + (0.0722 * color.b / 255);

    return new Dimension(luminance * color.alpha * 100, '%');

//    luminance: function (color) {
//        var luminance =
//            (0.2126 * color.rgb[0] / 255)
//          + (0.7152 * color.rgb[1] / 255)
//          + (0.0722 * color.rgb[2] / 255);
//
//        return new(tree.Dimension)(luminance * color.alpha * 100, '%');
//    },
  }

  ///
  /// Increase the saturation of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: saturate(hsl(90, 80%, 50%), 20%)
  ///   Output: #80ff00 // hsl(90, 100%, 50%)
  ///
  Color saturate(color, [Dimension amount]) {
    // filter: saturate(3.2);
    // should be kept as is, so check for color
    if (color is! Color) return null;

    HSLType hsl = color.toHSL();

    hsl.s += amount.value / 100;
    hsl.s = clamp(hsl.s);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    saturate: function (color, amount) {
//        // filter: saturate(3.2);
//        // should be kept as is, so check for color
//        if (!color.rgb) {
//            return null;
//        }
//        var hsl = color.toHSL();
//
//        hsl.s += amount.value / 100;
//        hsl.s = clamp(hsl.s);
//        return hsla(hsl);
//    },
  }

  ///
  /// Decrease the saturation of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: desaturate(hsl(90, 80%, 50%), 20%)
  ///   Output: #80cc33 // hsl(90, 60%, 50%)
  ///
  Color desaturate(Color color, Dimension amount) {
    HSLType hsl = color.toHSL();

    hsl.s -= amount.value / 100;
    hsl.s = clamp(hsl.s);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    desaturate: function (color, amount) {
//        var hsl = color.toHSL();
//
//        hsl.s -= amount.value / 100;
//        hsl.s = clamp(hsl.s);
//        return hsla(hsl);
//    },
  }

  ///
  /// Increase the lightness of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: lighten(hsl(90, 80%, 50%), 20%)
  ///   Output: #b3f075 // hsl(90, 80%, 70%)
  ///
  Color lighten(Color color, Dimension amount) {
    HSLType hsl = color.toHSL();

    hsl.l += amount.value / 100;
    hsl.l = clamp(hsl.l);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    lighten: function (color, amount) {
//        var hsl = color.toHSL();
//
//        hsl.l += amount.value / 100;
//        hsl.l = clamp(hsl.l);
//        return hsla(hsl);
//    },
  }

  ///
  /// Decrease the lightness of a color in the HSL color space by an absolute amount.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: darken(hsl(90, 80%, 50%), 20%)
  ///   Output: #4d8a0f // hsl(90, 80%, 30%)
  ///
  Color darken(Color color, Dimension amount) {
    HSLType hsl = color.toHSL();

    hsl.l -= amount.value / 100;
    hsl.l = clamp(hsl.l);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    darken: function (color, amount) {
//        var hsl = color.toHSL();
//
//        hsl.l -= amount.value / 100;
//        hsl.l = clamp(hsl.l);
//        return hsla(hsl);
//    },
  }

  ///
  /// Decrease the transparency (or increase the opacity) of a color, making it more opaque.
  //
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: fadein(hsla(90, 90%, 50%, 0.5), 10%)
  ///   Output: rgba(128, 242, 13, 0.6) // hsla(90, 90%, 50%, 0.6)
  ///
  Color fadein(Color color, Dimension amount) {
    HSLType hsl = color.toHSL();

    hsl.a += amount.value / 100;
    hsl.a = clamp(hsl.a);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    fadein: function (color, amount) {
//        var hsl = color.toHSL();
//
//        hsl.a += amount.value / 100;
//        hsl.a = clamp(hsl.a);
//        return hsla(hsl);
//    },
  }

  ///
  /// Increase the transparency (or decrease the opacity) of a color, making it less opaque.
  ///
  /// Parameters:
  ///   color: A color object.
  ///   amount: A percentage 0-100%.
  ///   Returns: color
  /// Example: fadeout(hsla(90, 90%, 50%, 0.5), 10%)
  ///   Output: rgba(128, 242, 13, 0.4) // hsla(90, 90%, 50%, 0.4)
  ///
  Color fadeout(Color color, Dimension amount) {
    HSLType hsl = color.toHSL();

    hsl.a -= amount.value / 100;
    hsl.a = clamp(hsl.a);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    fadeout: function (color, amount) {
//        var hsl = color.toHSL();
//
//        hsl.a -= amount.value / 100;
//        hsl.a = clamp(hsl.a);
//        return hsla(hsl);
//    },
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
  Color fade(Color color, Dimension amount) {
    HSLType hsl = color.toHSL();

    hsl.a = amount.value / 100;
    hsl.a = clamp(hsl.a);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    fade: function (color, amount) {
//        var hsl = color.toHSL();
//
//        hsl.a = amount.value / 100;
//        hsl.a = clamp(hsl.a);
//        return hsla(hsl);
//    },
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
  spin(color, amount) {
    HSLType hsl = color.toHSL();
    double hue = (hsl.h + amount.value) % 360;

    hsl.h = hue < 0 ? 360 + hue : hue;
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//    spin: function (color, amount) {
//        var hsl = color.toHSL();
//        var hue = (hsl.h + amount.value) % 360;
//
//        hsl.h = hue < 0 ? 360 + hue : hue;
//
//        return hsla(hsl);
//    },
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
  // Copyright (c) 2006-2009 Hampton Catlin, Nathan Weizenbaum, and Chris Eppstein
  // http://sass-lang.com
  Color mix(Color color1, Color color2, [weight]) {
    if (weight == null) weight = new Dimension(50);

    double p = weight.value / 100.0;
    double w = p * 2 - 1;
    double a = color1.toHSL().a - color2.toHSL().a;

    double w1 = (((w * a == -1) ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
    double w2 = 1 - w1;

    List rgb = [color1.r * w1 + color2.r * w2,
                color1.g * w1 + color2.g * w2,
                color1.b * w1 + color2.b * w2];
    double alpha = color1.alpha * p + color2.alpha * (1 - p);

    return new Color(rgb, alpha);

//    mix: function (color1, color2, weight) {
//        if (!weight) {
//            weight = new(tree.Dimension)(50);
//        }
//        var p = weight.value / 100.0;
//        var w = p * 2 - 1;
//        var a = color1.toHSL().a - color2.toHSL().a;
//
//        var w1 = (((w * a == -1) ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
//        var w2 = 1 - w1;
//
//        var rgb = [color1.rgb[0] * w1 + color2.rgb[0] * w2,
//                   color1.rgb[1] * w1 + color2.rgb[1] * w2,
//                   color1.rgb[2] * w1 + color2.rgb[2] * w2];
//
//        var alpha = color1.alpha * p + color2.alpha * (1 - p);
//
//        return new(tree.Color)(rgb, alpha);
//    },
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
  Color greyscale(Color color) => this.desaturate(color, new Dimension(100));

  ///
  /// Choose which of two colors provides the greatest contrast with another.
  ///
  /// Parameters:
  ///   color: A color object to compare against.
  ///   dark: optional - A designated dark color (defaults to black).
  ///   light: optional - A designated light color (defaults to white).
  ///   threshold: optional - A percentage 0-100% specifying where the
  ///     transition from "dark" to "light" is (defaults to 43%, matching SASS).
  ///   Returns: color
  ///
  Color contrast(color, [Color dark, Color light, Dimension threshold]) {
    // filter: contrast(3.2);
    // should be kept as is, so check for color
    if (color is! Color) return null;

    if (light == null) light = this.rgba(255, 255, 255, 1.0);
    if (dark == null)  dark = this.rgba(0, 0, 0, 1.0);

    //Figure out which is actually light and dark!
    if (dark.luma() > light.luma()) {
      Color t = light;
      light = dark;
      dark = t;
    }

    double thresholdValue;

    if (threshold == null) {
      thresholdValue = 0.43;
    } else {
      thresholdValue = number(threshold);
    }
    if (color.luma() < thresholdValue) {
      return light;
    } else {
      return dark;
    }

//    contrast: function (color, dark, light, threshold) {
//        // filter: contrast(3.2);
//        // should be kept as is, so check for color
//        if (!color.rgb) {
//            return null;
//        }
//        if (typeof light === 'undefined') {
//            light = this.rgba(255, 255, 255, 1.0);
//        }
//        if (typeof dark === 'undefined') {
//            dark = this.rgba(0, 0, 0, 1.0);
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
//    },
  }

  //--------- Color Blend ----------------------------

  //
  /// Multiply two colors. Corresponding RGB channels from each of the two colors
  /// are multiplied together then divided by 255. The result is a darker color.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   Returns: color
  ///
  Color multiply (Color color1, Color color2) {
    return this.colorBlend.call('multiply', color1, color2);
  }

  ///
  /// Do the opposite of multiply. The result is a brighter color.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   Returns: color
  ///
  Color screen (Color color1, Color color2) {
    return this.colorBlend.call('screen', color1, color2);
  }

  ///
  /// Combines the effects of both multiply and screen. Conditionally make light
  /// channels lighter and dark channels darker.
  ///
  /// Parameters:
  ///   color1: A base color object. Also the determinant color to make the result lighter or darker.
  ///   color2: A color object to overlay.
  ///   Returns: color
  ///
  Color overlay (Color color1, Color color2) {
    return this.colorBlend.call('overlay', color1, color2);
  }

  ///
  /// Similar to overlay but avoids pure black resulting in pure black, and pure
  /// white resulting in pure white.
  ///
  /// Parameters:
  ///   color1: A color object to soft light another.
  ///   color2: A color object to be soft lighten.
  ///   Returns: color
  ///
  Color softlight (Color color1, Color color2) {
    return this.colorBlend.call('softlight', color1, color2);
  }

  ///
  /// The same as overlay but with the color roles reversed.
  ///
  /// Parameters:
  ///   color1: A color object to overlay.
  ///   color2: A base color object. Also the determinant color to make the result lighter or darker.
  ///   Returns: color
  ///
  Color hardlight (Color color1, Color color2) {
    return this.colorBlend.call('hardlight', color1, color2);
  }

  ///
  /// Subtracts the second color from the first color on a channel-by-channel basis.
  /// Negative values are inverted. Subtracting black results in no change;
  /// subtracting white results in color inversion.
  ///
  /// Parameters:
  ///   color1: A color object to act as the minuend.
  ///   color2: A color object to act as the subtrahend.
  ///   Returns: color
  ///
  Color difference (Color color1, Color color2) {
    return this.colorBlend.call('difference', color1, color2);
  }

  ///
  /// A similar effect to difference with lower contrast.
  ///
  /// Parameters:
  ///   color1: A color object to act as the minuend.
  ///   color2: A color object to act as the subtrahend.
  ///   Returns: color
  ///
  Color exclusion (Color color1, Color color2) {
    return this.colorBlend.call('exclusion', color1, color2);
  }

  ///
  /// Compute the average of two colors on a per-channel (RGB) basis.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   Returns: color
  ///
  Color average (Color color1, Color color2) {
    return this.colorBlend.call('average', color1, color2);
  }

  ///
  /// Do the opposite effect to difference.
  /// The result is a brighter color.
  ///
  /// Parameters:
  ///   color1: A color object to act as the minuend.
  ///   color2: A color object to act as the subtrahend.
  ///   Returns: color
  ///
  Color negation (Color color1, Color color2) {
    return this.colorBlend.call('negation', color1, color2);
  }

  //--------- String Functions -------------------------------------------

  ///
  /// CSS escaping, replaced with ~"value" syntax.
  /// It expects string as a parameter and return its content as is, but without quotes.
  /// Parameters:
  ///   string - a string to escape.
  ///   Returns: string - the escaped string, without quotes.
  /// Example:
  ///   filter: e("ms:alwaysHasItsOwnSyntax.For.Stuff()");
  ///   Output: filter: ms:alwaysHasItsOwnSyntax.For.Stuff();
  /// Note: The function accepts also ~"" escaped values and numbers as parameters.
  /// Anything else returns an error.
  ///
  Anonymous e(Node str) {
    return new Anonymous(str is JavaScript ? null : str.value); //TODO str.evaluated ???


//    e: function (str) {
//        return new(tree.Anonymous)(str instanceof tree.JavaScript ? str.evaluated : str.value);
//    },
  }

  ///
  /// Applies URL-encoding to special characters found in the input string.
  /// These characters are not encoded: ,, /, ?, @, &, +, ', ~, ! and $.
  /// Most common encoded characters are: \<space\>, #, ^, (, ), {, }, |, :, >, <, ;, ], [ and =.
  ///
  /// Parameters:
  ///   string: a string to escape.
  ///   Returns: escaped string content without quotes.
  /// Example:
  ///   escape('a=1')
  ///   Output: a%3D1
  /// Note: if the parameter is not a string, output is not defined.
  /// The current implementation returns undefined on color and unchanged input
  /// on any other kind of argument. This behavior should not be relied on and may change in the future.
  Anonymous escape(Node str) {
    return new Anonymous(Uri.encodeFull(str.value)
                          ..replaceAll(new RegExp(r'='), '%3D')
                          ..replaceAll(new RegExp(r':'), '%3A')
                          ..replaceAll(new RegExp(r'#'), '%23')
                          ..replaceAll(new RegExp(r';'), '%3B')
                          ..replaceAll(new RegExp(r'('), '%28')
                          ..replaceAll(new RegExp(r')'), '%29'));

//    escape: function (str) {
//        return new(tree.Anonymous)(encodeURI(str.value).replace(/=/g, "%3D").replace(/:/g, "%3A").replace(/#/g, "%23").replace(/;/g, "%3B").replace(/\(/g, "%28").replace(/\)/g, "%29"));
//    },
  }

  ///
  /// Replaces a text within a string.
  //
  /// Parameters:
  ///   string: The string to search and replace in.
  ///   pattern: A string or regular expression pattern to search for.
  ///   replacement: The string to replace the matched pattern with.
  ///   flags: (Optional) regular expression flags.
  ///   Returns: a string with the replaced values.
  /// Example:
  ///   replace("Hello, Mars?", "Mars\?", "Earth!");
  ///   replace("One + one = 4", "one", "2", "gi");
  ///   replace('This is a string.', "(string)\.$", "new $1.");
  ///   replace(~"bar-1", '1', '2');
  ///   Result:
  ///     "Hello, Earth!";
  ///     "2 + 2 = 4";
  ///     'This is a new string.';
  ///     bar-2;
  ///
  Quoted replace(Node string, Quoted pattern, Quoted replacement, [Quoted flags]) {
    //string is Quoted, Keyword
    String flagsValue = flags != null ? flags.value : '';
    RegExpExtended re = new RegExpExtended(pattern.value, flagsValue);
    String result = re.replace(string.value, replacement.value);
    String quote = (string is Quoted) ? string.quote : '';
    bool escaped = (string is Quoted) ? string.escaped : false;
    return new Quoted(quote, result, escaped);


//    replace: function (string, pattern, replacement, flags) {
//        var result = string.value;
//
//        result = result.replace(new RegExp(pattern.value, flags ? flags.value : ''), replacement.value);
//        return new(tree.Quoted)(string.quote || '', result, string.escaped);
//    },
  }

  ///
  /// % format
  /// The function %(string, arguments ...) formats a string.
  ///
  /// The first argument is string with placeholders. All placeholders start
  /// with percentage symbol % followed by letter s,S,d,D,a, or A.
  /// Remaining arguments contain expressions to replace placeholders.
  ///
  /// Placeholders:
  ///   d, D, a, A - can be replaced by any kind of argument
  ///     (color, number, escaped value, expression, ...). If you use them in
  ///     combination with string, the whole string will be used - including its
  ///     quotes. However, the quotes are placed into the string as they are,
  ///     they are not escaped by "/" nor anything similar.
  ///   s, S - can be replaced by any kind of argument except color. If you use
  ///     them in combination with string, only the string value will be used
  ///     - string quotes are omitted.
  /// Parameters:
  ///   string: format string with placeholders,
  ///   anything* : values to replace placeholders.
  /// Returns: formatted string.
  /// Example:
  ///   format-a-d: %("repetitions: %a file: %d", 1 + 2, "directory/file.less");
  ///   Output:
  ///     format-a-d: "repetitions: 3 file: "directory/file.less"";
  ///
  Quoted format(List<Node> args) {
    Quoted qstr = args[0];
    String result = qstr.value;
    RegExpExtended sda = new RegExpExtended(r'%[sda]','i');
    RegExp az = new RegExp(r'[A-Z]$', caseSensitive: true);

    for (int i = 1; i < args.length; i++) {
      result = sda.replaceMap(result, (Match m) {
        String value =  m[0].toLowerCase() == '%s' ? args[i].value : args[i].toCSS(env);
        return az.hasMatch(m[0]) ? Uri.encodeComponent(value) : value;
      });
    }
    result.replaceAll(new RegExp(r'%%'), '%');
    return new Quoted(getValueOrDefault(qstr.quote, ''), result, qstr.escaped, qstr.index, currentFileInfo);

//-    Quoted qstr = args[0];
//-    String result = qstr.value;
//-
//-    RegExp sda = new RegExp(r'%[sda]', caseSensitive: false);
//-    RegExp az = new RegExp(r'[A-Z]$', caseSensitive: true);
//-    Match m;
//-    String value;
//-
//-    for (int i = 1; i < args.length; i++) { //TODO TESTING !!!
//-      m = sda.firstMatch(result);
//-      value = m[1].toLowerCase() == 's' ? args[i].value : args[i].toCSS(env);
//-      value = az.hasMatch(m[1]) ? Uri.encodeComponent(value) : value;
//-      result = result.replaceFirst(sda, value);
//-    }
//-    result.replaceAll(new RegExp(r'%%'), '%');
//-    return new Quoted(getValueOrDefault(qstr.quote, ''), result, qstr.escaped, qstr.index, currentFileInfo);

//    '%': function (string /* arg, arg, ...*/) {
//        var args = Array.prototype.slice.call(arguments, 1),
//            result = string.value;
//
//        for (var i = 0; i < args.length; i++) {
//            /*jshint loopfunc:true */
//            result = result.replace(/%[sda]/i, function(token) {
//                var value = token.match(/s/i) ? args[i].value : args[i].toCSS();
//                return token.match(/[A-Z]$/) ? encodeURIComponent(value) : value;
//            });
//        }
//        result = result.replace(/%%/g, '%');
//        return new(tree.Quoted)(string.quote || '', result, string.escaped);
//    },
  }

//-------------------- Misc functions ---------------

  ///
  /// Remove or change the unit of a dimension
  ///
  /// Parameters:
  ///   dimension: A number, with or without a dimension.
  ///   unit: (Optional) the unit to change to, or if omitted it will remove the unit.
  /// Example:
  ///   unit(5, px)
  ///   Output: 5px
  ///
  Dimension unit(Node val, [Node unit]) {
    var unitValue;

    if (val is! Dimension) {
      String p = val is Operation ? '. Have you forgotten parenthesis?' : '';
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'the first argument to unit must be a number${p}'));
    }
    if (unit != null) {
      if (unit is Keyword) {
        unitValue = unit.value;
      } else {
        unitValue = unit.toCSS(this.env);
      }
    } else {
      unitValue = '';
    }
    return new Dimension(val.value, unitValue);

//    unit: function (val, unit) {
//        if(!(val instanceof tree.Dimension)) {
//            throw { type: "Argument", message: "the first argument to unit must be a number" + (val instanceof tree.Operation ? ". Have you forgotten parenthesis?" : "") };
//        }
//        if (unit) {
//            if (unit instanceof tree.Keyword) {
//                unit = unit.value;
//            } else {
//                unit = unit.toCSS();
//            }
//        } else {
//            unit = "";
//        }
//        return new(tree.Dimension)(val.value, unit);
//    },
  }

  ///
  /// Convert a number from one unit into another.
  ///
  /// The first argument contains a number with units and second argument contains units.
  /// If the units are compatible, the number is converted.
  /// If they are not compatible, the first argument is returned unmodified.
  ///
  /// Compatible unit groups:
  ///   lengths: m, cm, mm, in, pt and pc,
  ///   time: s and ms,
  ///   angle: rad, deg, grad and turn.
  /// Parameters:
  ///   number: a floating point number with units.
  ///   identifier, string or escaped value: units
  ///   Returns: number
  /// Example:
  ///   convert(9s, "ms")
  ///   Output: 9000ms
  ///
  Dimension convert(Dimension val, Node unit) => val.convertTo(unit.value);

  ///
  /// Applies rounding.
  ///
  /// Parameters:
  ///   number: A floating point number.
  ///   decimalPlaces: Optional: The number of decimal places to round to. Defaults to 0.
  ///   Returns: number
  /// Example: round(1.67)
  ///   Output: 2
  /// Example: round(1.67, 1)
  ///   Output: 1.7
  ///
  Dimension round(Node n, [Node f]) {
    num fraction = (f == null) ? 0 : f.value;
    return _math((num d) {
      double exp = math.pow(10, fraction).toDouble();
      return (d * exp).roundToDouble()/ exp;
    }, null, n);

//    round: function (n, f) {
//        var fraction = typeof(f) === "undefined" ? 0 : f.value;
//        return _math(function(num) { return num.toFixed(fraction); }, null, n);
//    },
  }

  ///
  /// Returns π (pi);
  ///
  /// Parameters: none
  ///   Returns: number
  /// Example:
  ///   pi()
  ///   Output: 3.141592653589793
  ///
  Dimension pi() => new Dimension(math.PI);

  ///
  /// Returns the value of the first argument modulus second argument.
  /// Returned value has the same dimension as the first parameter, the dimension
  /// of the second parameter is ignored.
  ///
  /// Parameters:
  ///   number: a floating point number.
  ///   number: a floating point number.
  ///   Returns: number
  /// Example:
  ///   mod(11cm, 6px);
  ///   Output: 5cm
  ///
  Dimension mod(Dimension a, Dimension b) => new Dimension(a.value % b.value, a.unit);

  ///
  /// Returns the value of the first argument raised to the power of the second argument.
  /// Returned value has the same dimension as the first parameter and the dimension of the second parameter is ignored.
  ///
  /// Parameters:
  ///   number: base -a floating point number.
  ///   number: exponent - a floating point number.
  ///   Returns: number
  /// Example:
  ///   pow(0cm, 0px)
  ///   Output: 1cm
  ///
  Dimension pow(x, y) {
    if (x is num && y is num) {
      x = new Dimension(x);
      y = new Dimension(y);
    } else if (x is! Dimension || y is! Dimension) {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'arguments must be numbers'));
    }

    return new Dimension(math.pow(x.value, y.value), x.unit);

//    pow: function(x, y) {
//        if (typeof x === "number" && typeof y === "number") {
//            x = new(tree.Dimension)(x);
//            y = new(tree.Dimension)(y);
//        } else if (!(x instanceof tree.Dimension) || !(y instanceof tree.Dimension)) {
//            throw { type: "Argument", message: "arguments must be numbers" };
//        }
//
//        return new(tree.Dimension)(Math.pow(x.value, y.value), x.unit);
//    },
  }

  Node _minmax(bool isMin, List<Node> args) {
    if (args.isEmpty) {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'one or more arguments required'));
    }

    int i;
    int j;
    Dimension current;
    Dimension currentUnified;
    Dimension referenceUnified;
    String unit;
    String unitStatic;
    String unitClone;
    // elems only contains original argument values.
    List<Dimension> order = [];
    // key is the unit.toString() for unified tree.Dimension values,
    // value is the index into the order array.
    Map values = {};

    for (i = 0; i < args.length; i++) {
      if (args[i] is! Dimension) {
        if (args[i].value is List) args.addAll(args[i].value);
        continue;
      }
      current = args[i];
      currentUnified = ( current.unit.toString() == '' && unitClone != null)
          ? new Dimension(current.value, unitClone).unify()
          : current.unify();
      unit = (currentUnified.unit.toString() == '' && unitStatic != null)
          ? unitStatic
          : currentUnified.unit.toString();
      unitStatic = (unit != '' && unitStatic == null || unit != '' && order[0].unify().unit.toString() == '')
          ? unit
          : unitStatic;
      unitClone = (unit != '' && unitClone == null)
          ? current.unit.toString()
          : unitClone;
      j = (values[''] != null && unit != '' && unit == unitStatic)
          ? values['']
          : values[unit];
      if (j == null) {
        if (unitStatic != null && unit != unitStatic) {
          throw new LessExceptionError(new LessError(
              type: 'Argument',
              message: 'incompatible types'));
        }
        values[unit] = order.length;
        order.add(current);
        continue;
      }
      referenceUnified = (order[j].unit.toString() == '' && unitClone != null)
          ? new Dimension(order[j].value, unitClone).unify()
          : order[j].unify();
      if (isMin && currentUnified.value < referenceUnified.value ||
         !isMin && currentUnified.value > referenceUnified.value) {
        order[j] = current;
      }
    }

    if (order.length == 1) return order[0];
    String arguments = order.map((a) => a.toCSS(this.env)).toList().join(this.env.compress ? ',' : ', ');
    return new Anonymous((isMin ? 'min' : 'max') + '(${args})');

//    _minmax: function (isMin, args) {
//        args = Array.prototype.slice.call(args);
//        switch(args.length) {
//            case 0: throw { type: "Argument", message: "one or more arguments required" };
//        }
//        var i, j, current, currentUnified, referenceUnified, unit, unitStatic, unitClone,
//            order  = [], // elems only contains original argument values.
//            values = {}; // key is the unit.toString() for unified tree.Dimension values,
//                         // value is the index into the order array.
//        for (i = 0; i < args.length; i++) {
//            current = args[i];
//            if (!(current instanceof tree.Dimension)) {
//                if(Array.isArray(args[i].value)) {
//                    Array.prototype.push.apply(args, Array.prototype.slice.call(args[i].value));
//                }
//                continue;
//            }
//            currentUnified = current.unit.toString() === "" && unitClone !== undefined ? new(tree.Dimension)(current.value, unitClone).unify() : current.unify();
//            unit = currentUnified.unit.toString() === "" && unitStatic !== undefined ? unitStatic : currentUnified.unit.toString();
//            unitStatic = unit !== "" && unitStatic === undefined || unit !== "" && order[0].unify().unit.toString() === "" ? unit : unitStatic;
//            unitClone = unit !== "" && unitClone === undefined ? current.unit.toString() : unitClone;
//            j = values[""] !== undefined && unit !== "" && unit === unitStatic ? values[""] : values[unit];
//            if (j === undefined) {
//                if(unitStatic !== undefined && unit !== unitStatic) {
//                    throw{ type: "Argument", message: "incompatible types" };
//                }
//                values[unit] = order.length;
//                order.push(current);
//                continue;
//            }
//            referenceUnified = order[j].unit.toString() === "" && unitClone !== undefined ? new(tree.Dimension)(order[j].value, unitClone).unify() : order[j].unify();
//            if ( isMin && currentUnified.value < referenceUnified.value ||
//                !isMin && currentUnified.value > referenceUnified.value) {
//                order[j] = current;
//            }
//        }
//        if (order.length == 1) {
//            return order[0];
//        }
//        args = order.map(function (a) { return a.toCSS(this.env); }).join(this.env.compress ? "," : ", ");
//        return new(tree.Anonymous)((isMin ? "min" : "max") + "(" + args + ")");
//    },
  }

  ///
  /// Returns the lowest of one or more values.
  ///
  /// Parameters: value1, ..., valueN - one or more values to compare.
  ///   Returns: the lowest value.
  /// Example: min(3px, 42px, 1px, 16px);
  ///   Output: 1px
  ///
  Node min(List arguments) => _minmax(true, arguments);

  ///
  /// Returns the highest of one or more values.
  ///
  /// Parameters: value1, ..., valueN - one or more values to compare.
  ///   Returns: the highest value.
  /// Example: max(3%, 42%, 1%, 16%);
  /// Output: 42%
  ///
  Node max(List arguments) => _minmax(false, arguments);

  ///
  /// get-unit
  /// Returns units of a number.
  ///
  /// If the argument contains a number with units, the function returns its units.
  /// The argument without units results in an empty return value.
  //
  /// Parameters:
  ///   number: a number with or without units.
  ///   Example: get-unit(5px)
  ///   Output: px
  /// Example: get-unit(5)
  ///   Output: //nothing
  ///
  Anonymous getUnit(Dimension n) => new Anonymous(n.unit);

//    "get-unit": function (n) {
//        return new(tree.Anonymous)(n.unit);
//    },

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
  Anonymous argb(Color color) => new Anonymous(color.toARGB());

  ///
  /// Converts a floating point number into a percentage string.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: string
  /// Example: percentage(0.5)
  ///   Output: 50%
  ///
  Dimension percentage(Node n) => new Dimension(n.value * 100, '%');


//-------------------- Misc functions ---------------

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
  Color color(n) {
    if (n is Quoted) {
      String colorCandidate = n.value;
      Color returnColor = new Color.fromKeyword(colorCandidate);
      if (returnColor != null) return returnColor;
      RegExp re = new RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})', caseSensitive: true);
      if (re.hasMatch(colorCandidate)) {
        return new Color(colorCandidate.substring(1)); // #rrggbb - without #
      }
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'argument must be a color keyword or 3/6 digit hex e.g. #FFF'));
    } else {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'argument must be a string'));
    }

//    color: function (n) {
//        if (n instanceof tree.Quoted) {
//            var colorCandidate = n.value,
//                returnColor;
//            returnColor = tree.Color.fromKeyword(colorCandidate);
//            if (returnColor) {
//                return returnColor;
//            }
//            if (/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/.test(colorCandidate)) {
//                return new(tree.Color)(colorCandidate.slice(1));
//            }
//            throw { type: "Argument", message: "argument must be a color keyword or 3/6 digit hex e.g. #FFF" };
//        } else {
//            throw { type: "Argument", message: "argument must be a string" };
//        }
//    },
  }

  //--------- Type ----------------------------

  ///
  /// Returns true if a value is a color, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a color, false otherwise.
  /// Example:
  ///   iscolor(#ff0);     // true
  ///   iscolor("string"); // false
  ///
  Keyword iscolor(n) {
    return (n is Color) ? new Keyword.True() : new Keyword.False();

//    iscolor: function (n) {
//        return this._isa(n, tree.Color);
//    },
  }

  ///
  /// Returns true if a value is a number, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a number, false otherwise.
  /// Example:
  ///   isnumber(#ff0);     // false
  ///   isnumber(1234);     // true
  ///
  Keyword isnumber(n) {
    return (n is Dimension) ? new Keyword.True() : new Keyword.False();

    //    isnumber: function (n) {
//        return this._isa(n, tree.Dimension);
//    },
  }

  ///
  /// Returns true if a value is a string, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a string, false otherwise.
  /// Example:
  ///   isstring(#ff0);     // false
  ///   isstring("string"); // true
  ///
  Keyword isstring(n) {
    return (n is Quoted) ? new Keyword.True() : new Keyword.False();

//    isstring: function (n) {
//        return this._isa(n, tree.Quoted);
//    },
  }

  ///
  /// Returns true if a value is a keyword, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a keyword, false otherwise.
  /// Example:
  ///   iskeyword(#ff0);     // false
  ///   iskeyword(keyword);  // true
  ///
  Keyword iskeyword(n) {
    return (n is Keyword) ? new Keyword.True() : new Keyword.False();

//    iskeyword: function (n) {
//        return this._isa(n, tree.Keyword);
//    },
  }

  ///
  /// Returns true if a value is a url, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a url, false otherwise.
  /// Example:
  ///   isurl(#ff0);     // false
  ///   isurl(url(...)); // true
  ///
  Keyword isurl(n) {
    return (n is URL) ? new Keyword.True() : new Keyword.False();

//    isurl: function (n) {
//        return this._isa(n, tree.URL);
//    },
  }

  ///
  /// Returns true if a value is a number in pixels, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a pixel, false otherwise.
  /// Example:
  ///   ispixel(#ff0);     // false
  ///   ispixel(56px);     // true
  ///
  Keyword ispixel(n) => isunit(n, 'px');

  ///
  /// Returns true if a value is a percentage value, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a percentage value, false otherwise.
  /// Example:
  ///   ispercentage(#ff0);     // false
  ///   ispercentage(7.8%);     // true
  ///
  Keyword ispercentage(n) => isunit(n, '%');

  ///
  /// Returns true if a value is an em value, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is an em value, false otherwise.
  /// Example:
  ///   isem(#ff0);     // false
  ///   isem(7.8em);    // true
  ///
  Keyword isem(n) => isunit(n, 'em');

  ///
  /// Returns true if a value is a number in specified units, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   unit - a unit identifier (optionaly quoted) to test for.
  ///   Returns: true if value is a number in specified units, false otherwise.
  /// Example:
  ///   isunit(11px, px);  // true
  ///   isunit(2.2%, px);  // false
  ///   isunit(56px, "%"); // false
  ///   isunit(7.8%, '%'); // true
  ///
  Keyword isunit(n, unit) {
    String unitValue = (unit is String) ? unit : unit.value;
    if (n is Dimension && n.unit.isUnit(unitValue)) {
      return new Keyword.True();
    } else {
      return new Keyword.False();
    }

//    isunit: function (n, unit) {
//        return (n instanceof tree.Dimension) && n.unit.is(unit.value || unit) ? tree.True : tree.False;
//    },
  }

//  _isa(n, Type) {
//    return (n is Type) ? new Kewyword.True() : new Keyword.False();

//    _isa: function (n, Type) {
//        return (n instanceof Type) ? tree.True : tree.False;
//    },
//  }

  ///
  /// returns a [color] [amount]% points *lighter*
  ///
  Color tint(Color color, Dimension amount) => this.mix(this.rgb(255, 255, 255), color, amount);

  ///
  /// returns a [color] [amount]% points *darker*
  ///
  Color shade(Color color, Dimension amount) => this.mix(this.rgb(0, 0, 0), color, amount);

  //-------------------  List Functions

  ///
  /// Returns the value at a specified position in a list.
  ///
  /// Parameters:
  ///   list - a comma or space separated list of values.
  ///   index - an integer that specifies a position of a list element to return.
  ///   Returns: a value at the specified position in a list.
  /// Example: extract(8px dotted red, 2);
  ///   Output: dotted
  ///
  Node extract(Node values, Node index) {
    int iIndex = (index.value as num).toInt() - 1; // (1-based index)
    if (iIndex < 0) return null;

    // handle non-array values as an array of length 1
    // return 'null' if index is invalid
    if (values.value is List) {
      return (iIndex >= values.value.length) ? null : values.value[iIndex];
    } else {
      return (iIndex > 0) ? null : values; //TODO ???
    }

//    extract: function(values, index) {
//        index = index.value - 1; // (1-based index)
//        // handle non-array values as an array of length 1
//        // return 'undefined' if index is invalid
//        return Array.isArray(values.value)
//            ? values.value[index] : Array(values)[index];
//    },
  }

  ///
  /// Returns the number of elements in a value list.
  ///
  /// Parameters:
  ///   list - a comma or space separated list of values.
  ///   Returns: an integer number of elements in a list
  /// Example: length(1px solid #0080ff);
  ///   Output: 3
  ///
  Dimension length(Node values) {
    int n = (values.value is List) ? values.value.length : 1;
    return new Dimension(n);

//    length: function(values) {
//        var n = Array.isArray(values.value) ? values.value.length : 1;
//        return new tree.Dimension(n);
//    },
  }

  ///
  /// Inlines a resource and falls back to url() if the ieCompat option is on a
  /// nd the resource is too large. If the MIME type is not given then node uses
  /// the mime package to determine the correct mime type.
  ///
  /// Parameters:
  ///   mimetype: (Optional) A MIME type string.
  ///   url: The URL of the file to inline.
  /// Example: data-uri('../data/image.jpg');
  ///   Output: url('data:image/jpeg;base64,bm90IGFjdHVhbGx5IGEganBlZyBmaWxlCg==');
  /// Example: data-uri('image/svg+xml;charset=UTF-8', 'image.svg');
  ///   Output: url("data:image/svg+xml;charset=UTF-8,%3Csvg%3E%3Ccircle%20r%3D%229%22%2F%3E%3C%2Fsvg%3E");
  ///
  URL dataURI(Node mimetypeNode, [Node filePathNode]) {
    NodeConsole console = new NodeConsole();
    bool useBase64 = false;
    String mimetype = mimetypeNode.value;
    String filePath = filePathNode != null ? filePathNode.value : mimetype;

    int fragmentStart = filePath.indexOf('#');
    String fragment = '';
    if (fragmentStart != -1) {
      fragment = filePath.substring(fragmentStart);
      filePath = filePath.substring(0, fragmentStart);
    }

    if (this.env.isPathRelative(filePath)) {
      if (this.currentFileInfo.relativeUrls) {
        filePath = path.normalize(path.join(this.currentFileInfo.currentDirectory, filePath));
      } else {
        filePath = path.normalize(path.join(this.currentFileInfo.entryPath, filePath));
      }
    }

    // detect the mimetype if not given
    if (filePathNode == null) {
      Mime mime = new Mime();
      mimetype = mime.lookup(filePath);

      // use base 64 unless it's an ASCII or UTF-8 format
      String charset = mime.charsetsLookup(mimetype);
      useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
      if (useBase64)  mimetype += ';base64';
    } else {
      useBase64 = new RegExp(r';base64$').hasMatch(mimetype);
    }

    List<int> buf = new File(filePath).readAsBytesSync();

    // IE8 cannot handle a data-uri larger than 32KB. If this is exceeded
    // and the --ieCompat flag is enabled, return a normal url() instead.

    int DATA_URI_MAX_KB = 32;
    int fileSizeInKB = buf.length ~/ 1024;
    if (fileSizeInKB >= DATA_URI_MAX_KB) {
      if (this.env.ieCompat) {
        if (!this.env.silent) {
          console.warn('Skipped data-uri embedding of ${filePath} because its size (${fileSizeInKB}KB) exceeds IE8-safe ${DATA_URI_MAX_KB}KB!');
        }
        //TODO replace 0 by this.index
        return new URL(getValueOrDefault(filePathNode, mimetypeNode), 0, this.currentFileInfo).eval(this.env);
      }
    }
    //buf = useBase64 ? Base64String.encode(buf) : Uri.encodeComponent(buf);
    String sbuf = useBase64 ? Base64String.encode(buf) : Uri.encodeComponent(new String.fromCharCodes(buf));

    //String uri = '"data:${mimetype},${buf}${fragment}"';
    String uri = '"data:${mimetype},${sbuf}${fragment}"';
    return new URL(new Anonymous(uri));

//    "data-uri": function(mimetypeNode, filePathNode) {
//
//        if (typeof window !== 'undefined') {
//            return new tree.URL(filePathNode || mimetypeNode, this.currentFileInfo).eval(this.env);
//        }
//
//        var mimetype = mimetypeNode.value;
//        var filePath = (filePathNode && filePathNode.value);
//
//        var fs = require('./fs'),
//            path = require('path'),
//            useBase64 = false;
//
//        if (arguments.length < 2) {
//            filePath = mimetype;
//        }
//
//        var fragmentStart = filePath.indexOf('#');
//        var fragment = '';
//        if (fragmentStart!==-1) {
//            fragment = filePath.slice(fragmentStart);
//            filePath = filePath.slice(0, fragmentStart);
//        }
//
//        if (this.env.isPathRelative(filePath)) {
//            if (this.currentFileInfo.relativeUrls) {
//                filePath = path.join(this.currentFileInfo.currentDirectory, filePath);
//            } else {
//                filePath = path.join(this.currentFileInfo.entryPath, filePath);
//            }
//        }
//
//        // detect the mimetype if not given
//        if (arguments.length < 2) {
//            var mime;
//            try {
//                mime = require('mime');
//            } catch (ex) {
//                mime = tree._mime;
//            }
//
//            mimetype = mime.lookup(filePath);
//
//            // use base 64 unless it's an ASCII or UTF-8 format
//            var charset = mime.charsets.lookup(mimetype);
//            useBase64 = ['US-ASCII', 'UTF-8'].indexOf(charset) < 0;
//            if (useBase64) { mimetype += ';base64'; }
//        }
//        else {
//            useBase64 = /;base64$/.test(mimetype);
//        }
//
//        var buf = fs.readFileSync(filePath);
//
//        // IE8 cannot handle a data-uri larger than 32KB. If this is exceeded
//        // and the --ieCompat flag is enabled, return a normal url() instead.
//        var DATA_URI_MAX_KB = 32,
//            fileSizeInKB = parseInt((buf.length / 1024), 10);
//        if (fileSizeInKB >= DATA_URI_MAX_KB) {
//
//            if (this.env.ieCompat !== false) {
//                if (!this.env.silent) {
//                    console.warn("Skipped data-uri embedding of %s because its size (%dKB) exceeds IE8-safe %dKB!", filePath, fileSizeInKB, DATA_URI_MAX_KB);
//                }
//
//                return new tree.URL(filePathNode || mimetypeNode, this.currentFileInfo).eval(this.env);
//            }
//        }
//
//        buf = useBase64 ? buf.toString('base64')
//                        : encodeURIComponent(buf);
//
//        var uri = "\"data:" + mimetype + ',' + buf + fragment + "\"";
//        return new(tree.URL)(new(tree.Anonymous)(uri));
//    },
  }

  ///
  /// svg-gradient function generates multi-stop svg gradients.
  /// It must have at least three parameters. First parameter specifies gradient
  /// type and direction and remaining parameters list colors and their positions.
  /// The position of first and last specified color are optional, remaining colors
  /// must have positions specified.
  //
  /// The direction must be one of to bottom, to right, to bottom right, to top right,
  /// ellipse or ellipse at center. The direction can be specified as both escaped value
  /// and space separated list of words.
  //
  /// Parameters:
  ///   escaped value or list of identifiers: direction
  ///   color [percentage] pair: first color and its relative position (position is optional)
  ///   color percent pair: (optional) second color and its relative position
  ///   ...
  ///   color percent pair: (optional) n-th color and its relative position
  ///   color [percentage] pair: last color and its relative position (position is optional)
  ///   Returns: url with base64 encoded svg gradient.
  ///
  URL svgGradient(List<Node> arguments) {
    throwArgumentDescriptor() {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'svg-gradient expects direction, start_color [start_position], [color position,]..., end_color [end_position]'));
    }

    if (arguments.length < 3) throwArgumentDescriptor();

    Node direction = arguments[0];
    List<Node> stops = arguments.sublist(1);
    String gradientDirectionSvg;
    String gradientType = 'linear';
    String rectangleDimension = 'x="0" y="0" width="1" height="1"';
    bool useBase64 = true;
    Env renderEnv = new Env()..compress = false;
    String returner;
    String directionValue = direction.toCSS(renderEnv);
    int i;
    var color;
    var position;
    var positionValue;
    num alpha;

    switch (directionValue) {
      case 'to bottom':
        gradientDirectionSvg = 'x1="0%" y1="0%" x2="0%" y2="100%"';
        break;
      case 'to right':
        gradientDirectionSvg = 'x1="0%" y1="0%" x2="100%" y2="0%"';
        break;
      case 'to bottom right':
        gradientDirectionSvg = 'x1="0%" y1="0%" x2="100%" y2="100%"';
        break;
      case 'to top right':
        gradientDirectionSvg = 'x1="0%" y1="100%" x2="100%" y2="0%"';
        break;
      case 'ellipse':
      case 'ellipse at center':
        gradientType = 'radial';
        gradientDirectionSvg = 'cx="50%" cy="50%" r="75%"';
        rectangleDimension = 'x="-50" y="-50" width="101" height="101"';
        break;
      default:
        throw new LessExceptionError(new LessError(
            type: 'Argument',
            message: "svg-gradient direction must be 'to bottom', 'to right', 'to bottom right', 'to top right' or 'ellipse at center'"));
    }
    returner = '<?xml version="1.0" ?>' +
        '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="100%" height="100%" viewBox="0 0 1 1" preserveAspectRatio="none">' +
        '<' + gradientType + 'Gradient id="gradient" gradientUnits="userSpaceOnUse" ' + gradientDirectionSvg + '>';

    for (i = 0; i < stops.length; i++) {
      if (stops[i].value != null) {
        color = stops[i].value[0];
        position = stops[i].value[1];
      } else {
        color = stops[i];
        position = null;
      }

      if ((color is! Color) || (!((i == 0 || i+1 == stops.length) && position == null) && !(position is Dimension))) {
        throwArgumentDescriptor();
      }
      positionValue = position != null ? position.toCSS(renderEnv) : i == 0 ? "0%" : "100%";
      alpha = color.alpha;
      returner += '<stop offset="' + positionValue + '" stop-color="' + color.toRGB() + '"' + (alpha < 1 ? ' stop-opacity="' + alpha.toString() + '"' : '') + '/>';
    }
    returner += '</' + gradientType + 'Gradient>' +
                '<rect ' + rectangleDimension + ' fill="url(#gradient)" /></svg>';

    if (useBase64) returner = Base64String.encode(returner);
    returner = "'data:image/svg+xml" + (useBase64 ? ";base64" : "") + "," + returner + "'";
    return new URL(new Anonymous(returner));

//    "svg-gradient": function(direction) {
//
//        function throwArgumentDescriptor() {
//            throw { type: "Argument", message: "svg-gradient expects direction, start_color [start_position], [color position,]..., end_color [end_position]" };
//        }
//
//        if (arguments.length < 3) {
//            throwArgumentDescriptor();
//        }
//        var stops = Array.prototype.slice.call(arguments, 1),
//            gradientDirectionSvg,
//            gradientType = "linear",
//            rectangleDimension = 'x="0" y="0" width="1" height="1"',
//            useBase64 = true,
//            renderEnv = {compress: false},
//            returner,
//            directionValue = direction.toCSS(renderEnv),
//            i, color, position, positionValue, alpha;
//
//        switch (directionValue) {
//            case "to bottom":
//                gradientDirectionSvg = 'x1="0%" y1="0%" x2="0%" y2="100%"';
//                break;
//            case "to right":
//                gradientDirectionSvg = 'x1="0%" y1="0%" x2="100%" y2="0%"';
//                break;
//            case "to bottom right":
//                gradientDirectionSvg = 'x1="0%" y1="0%" x2="100%" y2="100%"';
//                break;
//            case "to top right":
//                gradientDirectionSvg = 'x1="0%" y1="100%" x2="100%" y2="0%"';
//                break;
//            case "ellipse":
//            case "ellipse at center":
//                gradientType = "radial";
//                gradientDirectionSvg = 'cx="50%" cy="50%" r="75%"';
//                rectangleDimension = 'x="-50" y="-50" width="101" height="101"';
//                break;
//            default:
//                throw { type: "Argument", message: "svg-gradient direction must be 'to bottom', 'to right', 'to bottom right', 'to top right' or 'ellipse at center'" };
//        }
//        returner = '<?xml version="1.0" ?>' +
//            '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="100%" height="100%" viewBox="0 0 1 1" preserveAspectRatio="none">' +
//            '<' + gradientType + 'Gradient id="gradient" gradientUnits="userSpaceOnUse" ' + gradientDirectionSvg + '>';
//
//        for (i = 0; i < stops.length; i+= 1) {
//            if (stops[i].value) {
//                color = stops[i].value[0];
//                position = stops[i].value[1];
//            } else {
//                color = stops[i];
//                position = undefined;
//            }
//
//            if (!(color instanceof tree.Color) || (!((i === 0 || i+1 === stops.length) && position === undefined) && !(position instanceof tree.Dimension))) {
//                throwArgumentDescriptor();
//            }
//            positionValue = position ? position.toCSS(renderEnv) : i === 0 ? "0%" : "100%";
//            alpha = color.alpha;
//            returner += '<stop offset="' + positionValue + '" stop-color="' + color.toRGB() + '"' + (alpha < 1 ? ' stop-opacity="' + alpha + '"' : '') + '/>';
//        }
//        returner += '</' + gradientType + 'Gradient>' +
//                    '<rect ' + rectangleDimension + ' fill="url(#gradient)" /></svg>';
//
//        if (useBase64) {
//            try {
//                returner = require('./encoder').encodeBase64(returner); // TODO browser implementation
//            } catch(e) {
//                useBase64 = false;
//            }
//        }
//
//        returner = "'data:image/svg+xml" + (useBase64 ? ";base64" : "") + "," + returner + "'";
//        return new(tree.URL)(new(tree.Anonymous)(returner));
//    }
//};
  }

//// Math

  ///
  /// Rounds up to the next highest integer.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: integer
  /// Example: ceil(2.4)
  ///   Output: 3
  ///
  Dimension ceil(Node n) => _math(_ceil, null, n);

  ///
  /// Rounds down to the next lowest integer.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: integer
  /// Example: floor(2.6)
  ///   Output: 2
  ///
  Dimension floor(Node n) => _math(_floor, null, n);

  ///
  /// Calculates square root of a number. Keeps units as they are.
  ///
  /// Parameters:
  ///   number - floating point number.
  ///   Returns: number
  /// Example: sqrt(25cm)
  ///   Output: 5cm
  ///
  Dimension sqrt(Node n) => _math(math.sqrt, null, n);

  ///
  /// Calculates absolute value of a number. Keeps units as they are.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example: abs(-18.6%)
  ///   Output: 18.6%;
  ///
  Dimension abs(Node n) => _math(_abs, null, n);

  ///
  /// Calculates tangent function.
  /// Assumes radians on numbers without units.
  //
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   tan(1deg) // tangent of 1 degree
  ///   Output: 0.017455064928217585
  ///
  Dimension tan(Node n) => _math(math.tan, '', n);

  ///
  /// Calculates sine function.
  /// Assumes radians on numbers without units.
  //
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   sin(1deg); // sine of 1 degree
  ///   Output: 0.01745240643728351;
  ///
  Dimension sin(Node n) => _math(math.sin, '', n);

  ///
  /// Calculates cosine function.
  /// Assumes radians on numbers without units.
  //
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   cos(1deg) // cosine of 1 degree
  ///   Output: 0.9998476951563913;
  ///
  Dimension cos(Node n) => _math(math.cos, '', n);

  ///
  /// Calculates arctangent (inverse of tangent) function.
  /// Returns number in radians e.g. a number between -π/2 and π/2.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   atan(-1.5574077246549023)
  /// Output: -1rad;
  ///
  Dimension atan(Node n) => _math(math.atan, 'rad', n);

  ///
  /// Calculates arcsine (inverse of sine) function.
  /// Returns number in radians e.g. a number between -π/2 and π/2.
  ///
  /// Parameters:
  ///   number - floating point number from [-1, 1] interval.
  ///   Returns: number
  /// Example:
  ///   asin(-0.8414709848078965)
  ///   Output: -1rad
  ///
  Dimension asin(Node n) => _math(math.asin, 'rad', n);

  ///
  /// Calculates arccosine (inverse of cosine) function.
  /// Returns number in radians e.g. a number between 0 and π.
  //
  /// Parameters:
  ///   number - a floating point number from [-1, 1] interval.
  ///   Returns: number
  /// Example:
  ///   acos(0.5403023058681398)
  ///   Output: 1rad
  ///
  Dimension acos(Node n) => _math(math.acos, 'rad', n);

  Dimension _math(Function fn, unit, Node n) {
    if (n is! Dimension) {
     throw new LessExceptionError(new LessError(
         type: 'Argument',
         message: 'argument must be a number'));
    }
    Dimension node = n as Dimension;
    if (unit == null) {
     unit = node.unit;
    } else {
     node = node.unify();
    }
    return new Dimension(fn(node.value.toDouble()), unit);
  }

  num _ceil(num n) => n.ceil();
  num _floor(num n) => n.floor();
  num _abs(num n) => n.abs();
//
//var mathFunctions = {
// // name,  unit
//    ceil:  null,
//    floor: null,
//    sqrt:  null,
//    abs:   null,
//    tan:   "",
//    sin:   "",
//    cos:   "",
//    atan:  "rad",
//    asin:  "rad",
//    acos:  "rad"
//};
//
//function _math(fn, unit, n) {
//    if (!(n instanceof tree.Dimension)) {
//        throw { type: "Argument", message: "argument must be a number" };
//    }
//    if (unit == null) {
//        unit = n.unit;
//    } else {
//        n = n.unify();
//    }
//    return new(tree.Dimension)(fn(parseFloat(n.value)), unit);
//}
//
// ~ End of Math
//
//
}

// these static methods are used as a fallback when the optional 'mime' dependency is missing
class Mime {
  // this map is intentionally incomplete
  // if you want more, install 'mime' dep

  Map<String, String> _types = {
    '.htm': 'text/html',
    '.html': 'text/html',
    '.gif': 'image/gif',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png'
  };

  String lookup(String filepath) {
    String ext = path.extension(filepath);
    String type = _types[ext];
    if (type == null) {
      throw new LessExceptionError(new LessError(
          message: 'Optional dependency "mime" is required for $type'));
    }
    return type;

//    lookup: function (filepath) {
//        var ext = require('path').extname(filepath),
//            type = tree._mime._types[ext];
//        if (type === undefined) {
//            throw new Error('Optional dependency "mime" is required for ' + ext);
//        }
//        return type;
//    },
  }

  String charsetsLookup(String type) {
    // assumes all text types are UTF-8
    RegExp re = new RegExp(r'^text\/');

    return (type != null && re.hasMatch(type)) ? 'UTF-8' : '';
  }

//    charsets: {
//        lookup: function (type) {
//            // assumes all text types are UTF-8
//            return type && (/^text\//).test(type) ? 'UTF-8' : '';
//        }
//    }
//};
//
}

// ref: http://www.w3.org/TR/compositing-1
class ColorBlend {
  Map<String, Function> methods;

  /// Color Blending
  ColorBlend() {
    methods = {
      'multiply': multiply,
      'screen': screen,
      'overlay': overlay,
      'softlight': softlight,
      'hardlight': hardlight,
      'difference': difference,
      'exclusion': exclusion,
      'average': average,
      'negation': negation
    };
  }

  /// [mode] is the Function name String, and [color1] [color2] the Color to blend.
  Color call(String mode, Color color1, Color color2) {
    Function fMode = methods[mode];

  // backdrop
    double ab = color1.alpha.toDouble();
    double cb;
  // source
    double as = color2.alpha.toDouble();
    double cs;
  // result
    double ar; // alpha result
    double cr; // channel result
    List r = [0, 0, 0];

    ar = as + ab * (1 - as);

    for (int i = 0; i < 3; i++) {
      cb = color1.rgb[i] / 255;
      cs = color2.rgb[i] / 255;
      cr = fMode(cb, cs);
      if (ar != 0) {
        cr = (as * cs + ab * (cb
              - as * (cb + cs - cr))) / ar;
      }
      r[i] = cr * 255;
    }
    return new Color(r, ar);


//function colorBlend(mode, color1, color2) {
//    var ab = color1.alpha, cb, // backdrop
//        as = color2.alpha, cs, // source
//        ar, cr, r = [];        // result
    //
//    ar = as + ab * (1 - as);
//    for (var i = 0; i < 3; i++) {
//        cb = color1.rgb[i] / 255;
//        cs = color2.rgb[i] / 255;
//        cr = mode(cb, cs);
//        if (ar) {
//            cr = (as * cs + ab * (cb
//                - as * (cb + cs - cr))) / ar;
//        }
//        r[i] = cr * 255;
//    }
    //
//    re.Color)(r, ar);
//}
  }

  ///
  double multiply(double cb, double cs) => cb * cs;

  ///
  double screen (double cb, double cs) => cb + cs - cb * cs;

  ///
  double overlay (double cb, double cs) {
    cb *= 2;
    return (cb <= 1) ? multiply(cb, cs) : screen(cb - 1, cs);

//    overlay: function(cb, cs) {
//        cb *= 2;
//        return (cb <= 1)
//            ? colorBlendMode.multiply(cb, cs)
//            : colorBlendMode.screen(cb - 1, cs);
//    },
  }

  ///
  double softlight (double cb, double cs) {
    double d = 1.0;
    double e = cb;

    if (cs > 0.5) {
      e = 1.0;
      d = (cb > 0.25) ? math.sqrt(cb)
                : ((16 * cb - 12) * cb + 4) * cb;
    }
    return cb - (1 - 2 * cs) * e * (d - cb);

//    softlight: function(cb, cs) {
//        var d = 1, e = cb;
//        if (cs > 0.5) {
//            e = 1;
//            d = (cb > 0.25) ? Math.sqrt(cb)
//                : ((16 * cb - 12) * cb + 4) * cb;
//        }
//        return cb - (1 - 2 * cs) * e * (d - cb);
//    },
  }

  ///
  double hardlight (double cb, double cs) => overlay(cs, cb);

  ///
  double difference (double cb, double cs) => (cb - cs).abs();

  ///
  double exclusion (double cb, double cs) => cb + cs - 2 * cb * cs;


  // non-w3c functions:

  ///
  double average (double cb, double cs) => (cb + cs) / 2;

  ///
  double negation (double cb, double cs) => 1 - (cb + cs - 1).abs();
}


//
//function initFunctions() {
//    var f, tf = tree.functions;
//
//    // math
//    for (f in mathFunctions) {
//        if (mathFunctions.hasOwnProperty(f)) {
//            tf[f] = _math.bind(null, Math[f], mathFunctions[f]);
//        }
//    }
//
//    // color blending
//    for (f in colorBlendMode) {
//        if (colorBlendMode.hasOwnProperty(f)) {
//            tf[f] = colorBlend.bind(null, colorBlendMode[f]);
//        }
//    }
//
//    // default
//    f = tree.defaultFunc;
//    tf["default"] = f.eval.bind(f);
//
//} initFunctions();


hsla(color) { //TODO
//function hsla(color) {
//    return tree.functions.hsla(color.h, color.s, color.l, color.a);
//}
}

///
scaled(n, size) {
  if (n is Dimension && n.unit.isUnit('%')) {
    return (n.value * size / 100);
  } else {
    return number(n);
  }
//function scaled(n, size) {
//    if (n instanceof tree.Dimension && n.unit.is('%')) {
//        return parseFloat(n.value * size / 100);
//    } else {
//        return number(n);
//    }
//}
}

///
number(n) {
  if (n is Dimension) {
    return n.unit.isUnit('%') ? n.value / 100 : n.value;
  } else if (n is num) {
    return n;
  } else {
    throw new LessExceptionError(new LessError(
        type: 'RuntimeError',
        message: 'color functions take numbers as parameters'));
  }

//function number(n) {
//    if (n instanceof tree.Dimension) {
//        return parseFloat(n.unit.is('%') ? n.value / 100 : n.value);
//    } else if (typeof(n) === 'number') {
//        return n;
//    } else {
//        throw {
//            error: "RuntimeError",
//            message: "color functions take numbers as parameters"
//        };
//    }
//}
}

///
/// Returns [val] clamped to be in the range 0..val..1.
/// Mantains type
///
clamp(num val) => (val is int) ? val.clamp(0, 1) : val.clamp(0.0,  1.0); //return type important
//function clamp(val) {
//    return Math.min(1, Math.max(0, val));
//}

///
/// Adjust the precision of [value] according to [env].numPrecision.
/// 8 By default.
/// #
num fround(Env env, num value) {  //TODO return string
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
//


// -------------------------------------------------------------------

class FunctionCall extends Functions {
  FunctionCall(Env env, FileInfo currentFileInfo) {
    this.env = env;
    this.currentFileInfo = currentFileInfo;
  }
}

// -------------------------------------------------------------------

class DefaultFunc {
  var value_;
  var error_;

  Node eval() {
    var v = this.value_;
    LessError e = this.error_;

    if (e != null) throw new LessExceptionError(e);
    if (v != null) return (v > 0) ? new Keyword.True() : new Keyword.False();
    return null;
//    eval: function () {
//        var v = this.value_, e = this.error_;
//        if (e) {
//            throw e;
//        }
//        if (v != null) {
//            return v ? tree.True : tree.False;
//        }
//    },
  }

  void value(v) {
    this.value_ = v;

//    value: function (v) {
//        this.value_ = v;
//    },
  }

  void error(LessError e) {
    this.error_ = e;

//    error: function (e) {
//        this.error_ = e;
//    },
  }

  void reset() {
    this.value_ = this.error_ = null;

//    reset: function () {
//        this.value_ = this.error_ = null;
//    }
  }
//};

}
