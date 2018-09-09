// source: lib/less-node/image-size.js 2.5.0

part of functions.less;

///
class ImageSizeFunctions extends FunctionBase {
  ///
  Environment environment = new Environment();
  ///
  ImageSize   imageSizeProcessor = new ImageSize();

  ///
  @defineMethodSkip
  ImageDimension imageSizeFtn(Quoted filePathNode) {
    String        filePath = filePathNode.value;
    final String  currentDirectory = currentFileInfo.relativeUrls
        ? currentFileInfo.currentDirectory
        : currentFileInfo.entryPath;

    final int fragmentStart = filePath.indexOf('#');
    if (fragmentStart != -1) {
      filePath = filePath.substring(0, fragmentStart);
    }

    final AbstractFileManager fileManager = environment.getFileManager(
        filePath, currentDirectory, context, environment, isSync: true);
    final FileLoaded fileSync = fileManager.existSync(
        filePath, currentDirectory, context, environment);
    if (fileSync.error != null) {
      throw fileSync.error;
    }

    return imageSizeProcessor.sizeOf(fileSync.filename);

//2.4.0 20150329
//  function imageSize(functionContext, filePathNode) {
//      var filePath = filePathNode.value;
//      var currentFileInfo = functionContext.currentFileInfo;
//      var currentDirectory = currentFileInfo.relativeUrls ?
//      currentFileInfo.currentDirectory : currentFileInfo.entryPath;
//
//      var fragmentStart = filePath.indexOf('#');
//      var fragment = '';
//      if (fragmentStart !== -1) {
//          fragment = filePath.slice(fragmentStart);
//          filePath = filePath.slice(0, fragmentStart);
//      }
//
//      var fileManager = environment.getFileManager(filePath, currentDirectory, functionContext.context, environment, true);
//
//      if (!fileManager) {
//          throw {
//              type: "File",
//              message: "Can not set up FileManager for " + filePathNode
//          };
//      }
//
//      var fileSync = fileManager.loadFileSync(filePath, currentDirectory, functionContext.context, environment);
//
//      if (fileSync.error) {
//          throw fileSync.error;
//      }
//
//      var sizeOf = require('image-size');
//      return sizeOf(fileSync.filename);
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
  @DefineMethod(name: 'image-size')
  Expression imageSize(Quoted filePathNode) {
    final ImageDimension size = imageSizeFtn(filePathNode);

    if (size == null) return null;

    return new Expression(<Node>[
      new Dimension(size.width, 'px'),
      new Dimension(size.height, 'px')
    ]);

//2.4.0 20150321
//  "image-size": function(filePathNode) {
//      var size = imageSize(this, filePathNode);
//      return new Expression([
//          new Dimension(size.width, "px"),
//          new Dimension(size.height, "px")
//      ]);
//  },
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
  @DefineMethod(name: 'image-width')
  Dimension imageWidth(Quoted filePathNode) {
    final ImageDimension size = imageSizeFtn(filePathNode);

    if (size == null) return null;

    return new Dimension(size.width, 'px');

//2.4.0 20150321
//  "image-width": function(filePathNode) {
//      var size = imageSize(this, filePathNode);
//      return new Dimension(size.width, "px");
//  },
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
  @DefineMethod(name: 'image-height')
  Dimension imageHeigth(Quoted filePathNode) {
    final ImageDimension size = imageSizeFtn(filePathNode);

    if (size == null) return null;

    return new Dimension(size.height, 'px');

//2.4.0 20150321
//  "image-height": function(filePathNode) {
//      var size = imageSize(this, filePathNode);
//      return new Dimension(size.height, "px");
//  }
  }
}
