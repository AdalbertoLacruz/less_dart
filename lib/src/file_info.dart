library fileInfo.less;

import 'contexts.dart';

/**
 * File Information
 */
class FileInfo {
  /// path to the current file, absolute
  String currentDirectory;

  /// absolute path to the entry file
  String entryPath;

  /// full resolved filename of current file
  String filename;

  /// whether the file should not be output and only output parts that are referenced
  bool reference = false;

  /// option - whether to adjust URL's to be relative
  bool relativeUrls;

  /// filename of the base file
  String rootFilename;

  /// path to append to normal URLs for this node
  String rootpath;

  /**
   * Empty default FileInfo creator.
   * ex.: FileInfo currentFileInfo = new FileInfo();
   * #
   */
  FileInfo();

  /**
   * Returns a new FileInfo for use in the fileLoader.
   * ex.: FileInfo newFileInfo = new FileInfo.cloneForLoader(currentFileInfo, env);
   * #
   */
  FileInfo.cloneForLoader(FileInfo current, Contexts env) {
    this.relativeUrls   = env.relativeUrls;
    this.entryPath      = current.entryPath;
    this.rootpath       = current.rootpath;
    this.rootFilename   = current.rootFilename;
  }
}