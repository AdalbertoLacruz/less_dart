// source: lib/less-node/image-size.js 2.4.0

part of functions.less;

class ImageSizeFunctions extends FunctionBase {
  Environment environment = new Environment();
  ImageSize imageSizeProcessor = new ImageSize();

  @defineMethod(skip: true)
  ImageDimension imageSizeFtn(Quoted filePathNode) {
    String filePath = filePathNode.value;
    String currentDirectory = filePathNode.currentFileInfo.relativeUrls
        ? filePathNode.currentFileInfo.currentDirectory
        : filePathNode.currentFileInfo.entryPath;
    filePath = environment.pathJoin(currentDirectory, filePath);
    return imageSizeProcessor.sizeOf(filePath);

//2.4.0
//  function imageSize(filePathNode) {
//      var filePath = filePathNode.value;
//      var currentDirectory = filePathNode.currentFileInfo.relativeUrls ?
//          filePathNode.currentFileInfo.currentDirectory : filePathNode.currentFileInfo.entryPath;
//
//      var sizeOf = require('image-size');
//      filePath = path.join(currentDirectory, filePath);
//      return sizeOf(filePath);
//  }
  }
//

  ///
  /// Gets the image dimensions from a file.
  ///
  /// Parameters:
  ///   string: the file to get the dimensions for.
  ///   Returns: dimension
  /// Example: image-size("file.png");
  ///   Output: 10px 10px
  ///
  @defineMethod(name: 'image-size')
  imageSize(Quoted filePathNode) {
    ImageDimension size = imageSizeFtn(filePathNode);
    if (size == null) return null;
    return new Expression([
      new Dimension(size.width, 'px'),
      new Dimension(size.height, 'px')
      ]);

//2.4.0
//  var imageFunctions = {
//      "image-size": function(filePathNode) {
//          var size = imageSize(filePathNode);
//          return new Expression([
//              new Dimension(size.width, "px"),
//              new Dimension(size.height, "px")
//          ]);
//      },
  }

  ///
  /// Gets the image width from a file.
  ///
  /// Parameters:
  ///   string: the file to get the dimensions for.
  ///   Returns: dimension
  /// Example: image-width("file.png");
  ///   Output: 10px
  ///
  @defineMethod(name: 'image-width')
  imageWidth(Quoted filePathNode) {
    ImageDimension size = imageSizeFtn(filePathNode);
    if (size == null) return null;
    return new Dimension(size.width, 'px');

//2.4.0
//      "image-width": function(filePathNode) {
//          var size = imageSize(filePathNode);
//          return new Dimension(size.width, "px");
//      },
  }

  ///
  /// Gets the image height from a file.
  ///
  /// Parameters:
  ///   string: the file to get the dimensions for.
  ///   Returns: dimension
  /// Example: image-height("file.png");
  ///   Output: 10px
  ///
  @defineMethod(name: 'image-height')
  imageHeigth(Quoted filePathNode) {
    ImageDimension size = imageSizeFtn(filePathNode);
    if (size == null) return null;
    return new Dimension(size.height, 'px');

//2.4.0
//      "image-height": function(filePathNode) {
//          var size = imageSize(filePathNode);
//          return new Dimension(size.height, "px");
//      }
//  };
  }
}