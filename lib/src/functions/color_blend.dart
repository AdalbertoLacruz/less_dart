// source: lib/less/functions/color-blending.js 2.5.0

part of functions.less;

// Color Blending
// ref: http://www.w3.org/TR/compositing-1
///
class ColorBlend extends FunctionBase {
  ///
  /// Mix two colors [color1] and [color2] according [fMode] function
  ///
  /// double fMmode(double cb, double cs)
  ///

  @defineMethodSkip
  Color colorBlend(Function fMode, Color color1, Color color2) {
    final ab = color1.alpha.toDouble(); // backdrop
    double cb;
    final as = color2.alpha.toDouble(); // source
    double cs;
    double ar; // alpha result
    double cr; // channel result
    final r = <num>[0, 0, 0];

    ar = as + ab * (1 - as);

    for (var i = 0; i < 3; i++) {
      cb = color1.rgb[i] / 255;
      cs = color2.rgb[i] / 255;
      cr = fMode(cb, cs) as double;
      if (ar != 0) cr = (as * cs + ab * (cb - as * (cb + cs - cr))) / ar;
      r[i] = cr * 255;
    }
    return Color.fromList(r, ar);

//    function colorBlend(mode, color1, color2) {
//        var ab = color1.alpha, cb, // backdrop
//            as = color2.alpha, cs, // source
//            ar, cr, r = [];        // result
//
//        ar = as + ab * (1 - as);
//        for (var i = 0; i < 3; i++) {
//            cb = color1.rgb[i] / 255;
//            cs = color2.rgb[i] / 255;
//            cr = mode(cb, cs);
//            if (ar) {
//                cr = (as * cs + ab * (cb -
//                      as * (cb + cs - cr))) / ar;
//            }
//            r[i] = cr * 255;
//        }
//
//        return new Color(r, ar);
//    }
  }

  //
  /// Multiply two colors. Corresponding RGB channels from each of the two colors
  /// are multiplied together then divided by 255. The result is a darker color.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   Returns: color
  ///
  Color multiply(Color color1, Color color2) =>
      colorBlend(fMultiply, color1, color2);

  ///
  @defineMethodSkip
  double fMultiply(double cb, double cs) => cb * cs;

  ///
  /// Do the opposite of multiply. The result is a brighter color.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   Returns: color
  ///
  Color screen(Color color1, Color color2) =>
      colorBlend(fScreen, color1, color2);

  ///
  @defineMethodSkip
  double fScreen(double cb, double cs) => cb + cs - cb * cs;

  ///
  /// Combines the effects of both multiply and screen. Conditionally make light
  /// channels lighter and dark channels darker.
  ///
  /// Parameters:
  ///   color1: A base color object. Also the determinant color to make the result lighter or darker.
  ///   color2: A color object to overlay.
  ///   Returns: color
  ///
  Color overlay(Color color1, Color color2) =>
      colorBlend(fOverlay, color1, color2);

  ///
  @defineMethodSkip
  double fOverlay(double cb, double cs) {
    final _cb = cb * 2;
    return (_cb <= 1) ? fMultiply(_cb, cs) : fScreen(_cb - 1, cs);

//    overlay: function(cb, cs) {
//        cb *= 2;
//        return (cb <= 1)
//            ? colorBlendModeFunctions.multiply(cb, cs)
//            : colorBlendModeFunctions.screen(cb - 1, cs);
//    }
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
  Color softlight(Color color1, Color color2) =>
      colorBlend(fSoftlight, color1, color2);

  ///
  @defineMethodSkip
  double fSoftlight(double cb, double cs) {
    var d = 1.0;
    var e = cb;

    if (cs > 0.5) {
      e = 1.0;
      d = (cb > 0.25) ? math.sqrt(cb) : ((16 * cb - 12) * cb + 4) * cb;
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
//    }
  }

  ///
  /// The same as overlay but with the color roles reversed.
  ///
  /// Parameters:
  ///   color1: A color object to overlay.
  ///   color2: A base color object. Also the determinant color to make the result lighter or darker.
  ///   Returns: color
  ///
  Color hardlight(Color color1, Color color2) =>
      colorBlend(fHardlight, color1, color2);

  ///
  @defineMethodSkip
  double fHardlight(double cb, double cs) => fOverlay(cs, cb);

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
  Color difference(Color color1, Color color2) =>
      colorBlend(fDifference, color1, color2);

  ///
  @defineMethodSkip
  double fDifference(double cb, double cs) => (cb - cs).abs();

  ///
  /// A similar effect to difference with lower contrast.
  ///
  /// Parameters:
  ///   color1: A color object to act as the minuend.
  ///   color2: A color object to act as the subtrahend.
  ///   Returns: color
  ///
  Color exclusion(Color color1, Color color2) =>
      colorBlend(fExclusion, color1, color2);

  ///
  @defineMethodSkip
  double fExclusion(double cb, double cs) => cb + cs - 2 * cb * cs;

  // non-w3c functions:

  ///
  /// Compute the average of two colors on a per-channel (RGB) basis.
  ///
  /// Parameters:
  ///   color1: A color object.
  ///   color2: A color object.
  ///   Returns: color
  ///
  Color average(Color color1, Color color2) =>
      colorBlend(fAverage, color1, color2);

  ///
  @defineMethodSkip
  double fAverage(double cb, double cs) => (cb + cs) / 2;

  ///
  /// Do the opposite effect to difference.
  /// The result is a brighter color.
  ///
  /// Parameters:
  ///   color1: A color object to act as the minuend.
  ///   color2: A color object to act as the subtrahend.
  ///   Returns: color
  ///
  Color negation(Color color1, Color color2) =>
      colorBlend(fNegation, color1, color2);

  ///
  @defineMethodSkip
  double fNegation(double cb, double cs) => 1 - (cb + cs - 1).abs();
}
