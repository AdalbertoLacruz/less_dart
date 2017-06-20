// source: lib/less/functions/svg.js 2.5.0

part of functions.less;

///
class SvgFunctions extends FunctionBase {
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
  ///   color percentage pair: first color and its relative position (position is optional)
  ///   color percent pair: (optional) second color and its relative position
  ///   ...
  ///   color percent pair: (optional) n-th color and its relative position
  ///   color percentage pair: last color and its relative position (position is optional)
  ///   Returns: url with base64 encoded svg gradient.
  ///
  @DefineMethod(name: 'svg-gradient', listArguments: true)
  URL svgGradient(List<Node> arguments) {
    void throwArgumentDescriptor() {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'svg-gradient expects direction, start_color [start_position], [color position,]..., end_color [end_position] or direction, color list'));
    }

    num             alpha;
    Node            color; //Color, except argument error
    final Node      direction = arguments[0];
    String          gradientDirectionSvg;
    String          gradientType = 'linear';
    Node            position; //Dimension, except argument error
    String          positionValue;
    String          rectangleDimension = 'x="0" y="0" width="1" height="1"';
    List<Node>      stops;
    final Contexts  renderEnv = new Contexts()
        ..compress = false
        ..numPrecision = context.numPrecision;
    String          returner;
    final StringBuffer    returnerSb = new StringBuffer();

    final String directionValue = direction.toCSS(renderEnv);

    if (arguments.length == 2) {
      if (arguments[1].value is! List || arguments[1].value.length < 2) {
        throwArgumentDescriptor();
      }
      stops = arguments[1].value;
    } else if (arguments.length < 3) {
      throwArgumentDescriptor();
    } else {
      stops = arguments.sublist(1);
    }

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

    //ignore: prefer_interpolation_to_compose_strings
    returnerSb
      ..write('<?xml version="1.0" ?>')
      ..write('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="100%" height="100%" viewBox="0 0 1 1" preserveAspectRatio="none">')
      ..write('<${gradientType}Gradient id="gradient" gradientUnits="userSpaceOnUse" $gradientDirectionSvg>');

    for (int i = 0; i < stops.length; i++) {
      if (stops[i] is Expression) {
        color = stops[i].value[0];
        position = stops[i].value[1];
      } else {
        color = stops[i];
        position = null;
      }

      if ((color is! Color) || (!((i == 0 || i + 1 == stops.length) && position == null) && !(position is Dimension))) {
        throwArgumentDescriptor();
      }

      positionValue = position != null
          ? position.toCSS(renderEnv) : i == 0 ? "0%"
          : "100%";
      final Color col = color;
      alpha = col.alpha;
      final String stopOpacity = (alpha < 1)
          ? ' stop-opacity="${alpha.toString()}"'
          : '';
      returnerSb.write('<stop offset="$positionValue" stop-color="${col.toRGB()}"$stopOpacity/>');
    }

    returnerSb.write('</${gradientType}Gradient><rect $rectangleDimension fill="url(#gradient)" /></svg>');
    returner = 'data:image/svg+xml,${Uri.encodeComponent(returnerSb.toString())}';
    return new URL(
        new Quoted("'$returner'", returner,
            escaped: false,
            index: index,
            currentFileInfo: currentFileInfo),
        index: index,
        currentFileInfo: currentFileInfo);

//2.4.0+
//  functionRegistry.add("svg-gradient", function(direction) {
//
//      var stops,
//          gradientDirectionSvg,
//          gradientType = "linear",
//          rectangleDimension = 'x="0" y="0" width="1" height="1"',
//          renderEnv = {compress: false},
//          returner,
//          directionValue = direction.toCSS(renderEnv),
//    i, color, position, positionValue, alpha;
//
//      function throwArgumentDescriptor() {
//          throw { type: "Argument",
//        message: "svg-gradient expects direction, start_color [start_position], [color position,]...," +
//            " end_color [end_position] or direction, color list" };
//      }
//
//      if (arguments.length == 2) {
//          if (arguments[1].value.length < 2) {
//              throwArgumentDescriptor();
//          }
//          stops = arguments[1].value;
//      } else if (arguments.length < 3) {
//          throwArgumentDescriptor();
//      } else {
//          stops = Array.prototype.slice.call(arguments, 1);
//      }
//
//      switch (directionValue) {
//          case "to bottom":
//              gradientDirectionSvg = 'x1="0%" y1="0%" x2="0%" y2="100%"';
//              break;
//          case "to right":
//              gradientDirectionSvg = 'x1="0%" y1="0%" x2="100%" y2="0%"';
//              break;
//          case "to bottom right":
//              gradientDirectionSvg = 'x1="0%" y1="0%" x2="100%" y2="100%"';
//              break;
//          case "to top right":
//              gradientDirectionSvg = 'x1="0%" y1="100%" x2="100%" y2="0%"';
//              break;
//          case "ellipse":
//          case "ellipse at center":
//              gradientType = "radial";
//              gradientDirectionSvg = 'cx="50%" cy="50%" r="75%"';
//              rectangleDimension = 'x="-50" y="-50" width="101" height="101"';
//              break;
//          default:
//              throw { type: "Argument", message: "svg-gradient direction must be 'to bottom', 'to right'," +
//                  " 'to bottom right', 'to top right' or 'ellipse at center'" };
//      }
//      returner = '<?xml version="1.0" ?>' +
//          '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="100%" height="100%" viewBox="0 0 1 1" preserveAspectRatio="none">' +
//          '<' + gradientType + 'Gradient id="gradient" gradientUnits="userSpaceOnUse" ' + gradientDirectionSvg + '>';
//
//      for (i = 0; i < stops.length; i+= 1) {
//          if (stops[i] instanceof Expression) {
//              color = stops[i].value[0];
//              position = stops[i].value[1];
//          } else {
//              color = stops[i];
//              position = undefined;
//          }
//
//          if (!(color instanceof Color) || (!((i === 0 || i + 1 === stops.length) && position === undefined) && !(position instanceof Dimension))) {
//              throwArgumentDescriptor();
//          }
//          positionValue = position ? position.toCSS(renderEnv) : i === 0 ? "0%" : "100%";
//          alpha = color.alpha;
//          returner += '<stop offset="' + positionValue + '" stop-color="' + color.toRGB() + '"' + (alpha < 1 ? ' stop-opacity="' + alpha + '"' : '') + '/>';
//      }
//      returner += '</' + gradientType + 'Gradient>' +
//          '<rect ' + rectangleDimension + ' fill="url(#gradient)" /></svg>';
//
//      returner = encodeURIComponent(returner);
//
//      returner = "data:image/svg+xml," + returner;
//      return new URL(new Quoted("'" + returner + "'", returner, false, this.index, this.currentFileInfo), this.index, this.currentFileInfo);
//  });
  }
}
