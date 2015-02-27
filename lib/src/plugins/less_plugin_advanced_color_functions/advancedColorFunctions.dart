part of less_plugin_advanced_color_functions.plugins.less;

class AdvancedColorFunctions extends ColorFunctions {

  ///
  /// Inverts the luma of a color giving a version darken or lighter than the original
  ///
  Color invertluma(Color color) {
    HSLType hsl = color.toHSL();
    hsl.l = 1 - hsl.l;
    hsl.l = clamp(hsl.l);
    return hsla(hsl.h, hsl.s, hsl.l, hsl.a);

//      invertluma: function( color ){
//          var hsl = color.toHSL();
//          hsl.l = 1 - hsl.l;
//          hsl.l = clamp(hsl.l);
//          return hsla(hsl);
//      },
  }

  ///
  /// If color1 and color2 have a similar luma, it contrast color2 a little bit more.
  /// If the color2 luma resultant is greater than 1, or less than 0, its luma is pivoted around color1 luma.
  ///
  Color contrastmore(Color color1, Color color2, [Dimension minLumaDifferenceDim]) {
    Color autocontrast = color2;
    double lumadif = (color1.luma() - autocontrast.luma()).abs();
    HSLType hsl = autocontrast.toHSL();
    double missingLumaDif;
    double newluma;
    double minLumaDifference = (minLumaDifferenceDim == null) ? 0.3 : minLumaDifferenceDim.value;

    if (lumadif < minLumaDifference) {
      missingLumaDif = minLumaDifference - lumadif;
      newluma = hsl.l;
      if (autocontrast.luma() > color1.luma()) {
        newluma += missingLumaDif;
      } else {
        newluma -= missingLumaDif;
      }
      newluma = clamp(newluma);
      hsl.l = newluma;
      autocontrast = hsla(hsl.h, hsl.s, hsl.l, hsl.a);
    }

    return autocontrast;

//      contrastmore: function( color1, color2, minLumaDifference){
//          var autocontrast = color2;
//          var lumadif = Math.abs( color1.luma() - autocontrast.luma() );
//          var hsl = autocontrast.toHSL();
//          var missingLumaDif;
//          var newluma;
//
//          if (typeof minLumaDifference === 'undefined') {
//              minLumaDifference = 0.3;
//          } else {
//              minLumaDifference = number(minLumaDifference);
//          }
//
//          if( lumadif < minLumaDifference ){
//              missingLumaDif = minLumaDifference - lumadif;
//              newluma = hsl.l;
//              if( autocontrast.luma() > color1.luma() ){
//                  newluma += missingLumaDif;
//              } else {
//                  newluma -= missingLumaDif;
//              }
//              newluma = clamp( newluma );
//              hsl.l = newluma;
//              autocontrast = hsla( hsl );
//          }
//
//          return autocontrast;
//      },
  }

  ///
  /// If color1 and color2 have a similar luma, it contrast color2 a little bit more.
  /// If the color2 luma resultant is greater than 1, or less than 0, its luma gets inverted.
  ///
  Color autocontrast(Color color1, Color color2, [Dimension minLumaDifferenceDim]) {
    Color autocontrast = color2;
    double lumadif = (color1.luma() - autocontrast.luma()).abs();
    HSLType hsl = autocontrast.toHSL();
    double newLuma = hsl.l;
    double missingLuma;

    double minLumaDifference = (minLumaDifferenceDim == null) ? 0.3 : minLumaDifferenceDim.value;

    if (lumadif < minLumaDifference) {
      missingLuma = minLumaDifference - lumadif;
      newLuma += ( missingLuma * ( color1.luma() < newLuma != 0 ? 1 : -1  ) );
      if( newLuma > 1 || newLuma < 0 ) newLuma = 1 - hsl.l;
      newLuma = clamp( newLuma );
      hsl.l = newLuma;
      autocontrast = hsla(hsl.h, hsl.s, hsl.l, hsl.a);
    }

    return autocontrast;

//      autocontrast: function( color1, color2, minLumaDifference){
//          var autocontrast = color2;
//          var lumadif = Math.abs( color1.luma() - autocontrast.luma() );
//          var hsl = autocontrast.toHSL();
//          var newLuma = hsl.l;
//          var missingLuma;
//
//          if (typeof minLumaDifference === 'undefined') {
//              minLumaDifference = 0.3;
//          } else {
//              minLumaDifference = number(minLumaDifference);
//          }
//
//          if( lumadif < minLumaDifference){
//              missingLuma = minLumaDifference - lumadif;
//              newLuma += ( missingLuma * ( color1.luma() < newLuma ? 1 : -1  ) );
//              if( newLuma > 1 || newLuma < 0 ){
//                  newLuma = 1 - hsl.l;
//              }
//              newLuma = clamp( newLuma );
//              hsl.l = newLuma;
//              autocontrast = hsla( hsl );
//          }
//
//          return autocontrast;
//      }
  }
}
