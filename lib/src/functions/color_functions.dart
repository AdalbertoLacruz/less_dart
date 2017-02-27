// source: lib/less/functions/color.js 2.5.0

part of functions.less;

class ColorFunctions extends FunctionBase {
  ///
  /// Returns [val] clamped to be in the range 0..val..1.
  /// Mantains type
  ///
  @defineMethod(skip: true)
  clamp(num val) => (val is int) ? val.clamp(0, 1) : val.clamp(0.0,  1.0); //return type important

//  function clamp(val) {
//      return Math.min(1, Math.max(0, val));
//  }

  //hsla(color) {
//  function hsla(color) {
//      return colorFunctions.hsla(color.h, color.s, color.l, color.a);
//  }
  //}

  ///
  /// [n] num | Node<Dimension> | error anything else
  /// 
  @defineMethod(skip: true)
  num number(n) {
    if (n is Dimension) {
      return n.unit.isUnit('%') ? n.value / 100 : n.value;
    } else if (n is num) {
      return n;
    } else {
      throw new LessExceptionError(new LessError(
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
  @defineMethod(skip: true)
  num scaled(n, size) {
    if (n is Dimension && n.unit.isUnit('%')) {
      return (n.value * size / 100);
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
  Color rgb(r, g, b) => rgba(r, g, b, 1.0);

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
//        return new Color(rgb, a);
//    }
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
  Color hsl(h, s, l) => hsla(h, s, l, 1.0);

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

    return rgba(
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
  Color hsv(h, s, v) => hsva(h, s, v, 1.0);

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

    return rgba(
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
  //
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
  Color saturate(color, [Dimension amount, Keyword method]) {
    // filter: saturate(3.2);
    // should be kept as is, so check for color
    if (color is! Color) return null;

    HSLType hsl = color.toHSL();

    if (method != null && method.value == 'relative') {
      hsl.s +=  hsl.s * amount.value / 100;
    } else {
      hsl.s += amount.value / 100;
    }

    hsl.s = clamp(hsl.s);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//2.4.0 20150315
//  saturate: function (color, amount, method) {
//      // filter: saturate(3.2);
//      // should be kept as is, so check for color
//      if (!color.rgb) {
//          return null;
//      }
//      var hsl = color.toHSL();
//
//      if (typeof method !== "undefined" && method.value === "relative") {
//          hsl.s +=  hsl.s * amount.value / 100;
//      }
//      else {
//          hsl.s += amount.value / 100;
//      }
//      hsl.s = clamp(hsl.s);
//      return hsla(hsl);
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
  Color desaturate(Color color, Dimension amount, [Keyword method]) {
    HSLType hsl = color.toHSL();

    if (method != null && method.value == 'relative') {
      hsl.s -=  hsl.s * amount.value / 100;
    } else {
      hsl.s -= amount.value / 100;
    }
    hsl.s = clamp(hsl.s);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//2.4.0 20150315
//  desaturate: function (color, amount, method) {
//      var hsl = color.toHSL();
//
//      if (typeof method !== "undefined" && method.value === "relative") {
//          hsl.s -=  hsl.s * amount.value / 100;
//      }
//      else {
//          hsl.s -= amount.value / 100;
//      }
//      hsl.s = clamp(hsl.s);
//      return hsla(hsl);
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
  Color lighten(Color color, Dimension amount, [Keyword method]) {
    HSLType hsl = color.toHSL();

    if (method != null && method.value == 'relative') {
      hsl.l +=  hsl.l * amount.value / 100;
    } else {
      hsl.l += amount.value / 100;
    }
    hsl.l = clamp(hsl.l);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//2.4.0 20150315
//  lighten: function (color, amount, method) {
//      var hsl = color.toHSL();
//
//      if (typeof method !== "undefined" && method.value === "relative") {
//          hsl.l +=  hsl.l * amount.value / 100;
//      }
//      else {
//          hsl.l += amount.value / 100;
//      }
//      hsl.l = clamp(hsl.l);
//      return hsla(hsl);
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
  Color darken(Color color, Dimension amount, [Keyword method]) {
    HSLType hsl = color.toHSL();

    if (method != null && method.value == 'relative') {
      hsl.l -=  hsl.l * amount.value / 100;
    } else {
      hsl.l -= amount.value / 100;
    }
    hsl.l = clamp(hsl.l);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//2.4.0 20150315
//  darken: function (color, amount, method) {
//      var hsl = color.toHSL();
//
//      if (typeof method !== "undefined" && method.value === "relative") {
//          hsl.l -=  hsl.l * amount.value / 100;
//      }
//      else {
//          hsl.l -= amount.value / 100;
//      }
//      hsl.l = clamp(hsl.l);
//      return hsla(hsl);
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
  Color fadein(Color color, Dimension amount, [Keyword method]) {
    HSLType hsl = color.toHSL();

    if (method != null && method.value == 'relative') {
      hsl.a +=  hsl.a * amount.value / 100;
    } else {
      hsl.a += amount.value / 100;
    }
    hsl.a = clamp(hsl.a);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//2.4.0 20150315
//  fadein: function (color, amount, method) {
//      var hsl = color.toHSL();
//
//      if (typeof method !== "undefined" && method.value === "relative") {
//          hsl.a +=  hsl.a * amount.value / 100;
//      }
//      else {
//          hsl.a += amount.value / 100;
//      }
//      hsl.a = clamp(hsl.a);
//      return hsla(hsl);
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
  Color fadeout(Color color, Dimension amount, [Keyword method]) {
    HSLType hsl = color.toHSL();

    if (method != null && method.value == 'relative') {
      hsl.a -=  hsl.a * amount.value / 100;
    } else {
      hsl.a -= amount.value / 100;
    }
    hsl.a = clamp(hsl.a);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//2.4.0 20150315
//  fadeout: function (color, amount, method) {
//      var hsl = color.toHSL();
//
//      if (typeof method !== "undefined" && method.value === "relative") {
//          hsl.a -=  hsl.a * amount.value / 100;
//      }
//      else {
//          hsl.a -= amount.value / 100;
//      }
//      hsl.a = clamp(hsl.a);
//      return hsla(hsl);
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
//    }
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
//    }
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
//            weight = new Dimension(50);
//        }
//        var p = weight.value / 100.0;
//        var w = p * 2 - 1;
//        var a = color1.toHSL().a - color2.toHSL().a;
//
//        var w1 = (((w * a == -1) ? w : (w + a) / (1 + w * a)) + 1) / 2.0;
//        var w2 = 1 - w1;
//
//        var rgb = [color1.rgb[0] * w1 + color2.rgb[0] * w2,
//            color1.rgb[1] * w1 + color2.rgb[1] * w2,
//            color1.rgb[2] * w1 + color2.rgb[2] * w2];
//
//        var alpha = color1.alpha * p + color2.alpha * (1 - p);
//
//        return new Color(rgb, alpha);
//    }
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
  Anonymous argb(Color color) => new Anonymous(color.toARGB());

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
  Color color(c) {
    RegExp re = new RegExp(r'^#([a-f0-9]{6}|[a-f0-9]{3})$', caseSensitive: false);

    if (c is Quoted && re.hasMatch(c.value)) {
      return new Color(c.value.substring(1)); // #rrggbb - without #
    }
    if (c is Color || (c = new Color.fromKeyword(c.value)) != null) {
      (c as Color).value = null;
      return c;
    }
    throw new LessExceptionError(new LessError(
        type: 'Argument',
        message: 'argument must be a color keyword or 3/6 digit hex e.g. #FFF'));

//2.2.0
//    color: function(c) {
//        if ((c instanceof Quoted) &&
//            (/^#([a-f0-9]{6}|[a-f0-9]{3})$/i.test(c.value))) {
//            return new Color(c.value.slice(1));
//        }
//        if ((c instanceof Color) || (c = Color.fromKeyword(c.value))) {
//            c.keyword = undefined;
//            return c;
//        }
//        throw {
//            type:    "Argument",
//            message: "argument must be a color keyword or 3/6 digit hex e.g. #FFF"
//        };
//    }
  }

  ///
  /// returns a [color] [amount]% points *lighter*
  ///
  Color tint(Color color, Dimension amount) => mix(rgb(255, 255, 255), color, amount);

  ///
  /// returns a [color] [amount]% points *darker*
  ///
  Color shade(Color color, Dimension amount) => mix(rgb(0, 0, 0), color, amount);
}
