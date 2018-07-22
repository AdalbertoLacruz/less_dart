part of builder.less;

///
/// Process .less files
///
class DotLessBuilder extends BaseBuilder {
  @override
  Future<BaseBuilder> transform(Function modifyOptions) {
    final Completer<BaseBuilder> task = new Completer<BaseBuilder>();

    runZoned(() {
      final Less less = new Less();
      less.stdin.write(inputContent);
      less.transform(flags, modifyOptions: modifyOptions).then((int exitCode) {
        if (exitCode == 0) {
          outputContent = less.stdout.toString();
          imports = less.imports;
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
