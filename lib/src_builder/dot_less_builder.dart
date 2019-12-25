part of builder.less;

///
/// Process .less files
///
class DotLessBuilder extends BaseBuilder {
  @override
  Future<BaseBuilder> transform(Function modifyOptions) {
    final task = Completer<BaseBuilder>();

    runZoned(() {
      final less = Less();
      less.stdin.write(inputContent);
      less.transform(flags, modifyOptions: modifyOptions).then((int exitCode) {
        if (exitCode == 0) {
          outputContent = less.stdout.toString();
          imports = less.imports;
          filesInPackage = less.filesInPackage;
        } else {
          isError = true;
          outputContent = errorMessage = less.stderr.toString();
        }
        less.loggerReset();
        task.complete(this);
      });
    }, zoneValues: <Symbol, int>{#id: GenId.next});

    return task.future;
  }
}
