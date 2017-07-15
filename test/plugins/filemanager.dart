part of batch.test.less;

///
class TestFileManager extends FileManager {
  ///
  TestFileManager(Environment environment) : super(environment);

  @override
  bool supports(String filename, String currentDirectory, Contexts options,
      Environment environment) => true;

  @override
  Future<FileLoaded> loadFile(String filename, String currentDirectory,
      Contexts options, Environment environment) {
    final RegExp testRe = new RegExp(r'.*\.test$');
    if (testRe.hasMatch(filename))
        return environment.fileManagers[0]
            .loadFile('colors.test', currentDirectory, options, environment);
    return environment.fileManagers[0]
        .loadFile(filename, currentDirectory, options, environment);
  }
}

///
class TestFileManagerPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FileManager fileManager = new TestFileManager(environment);
    pluginManager.addFileManager(fileManager);
  }
}
