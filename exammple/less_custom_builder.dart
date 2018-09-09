import 'package:less_dart/less_builder.dart';

// build.yaml example in test_less_dart project:
/*
builders:
  test_less_dart:
    import: 'package:test_less_dart/less_custom_builder.dart'
    builder_factories: ['lessCustomBuilder']
    auto_apply: dependents
    build_extensions:
          .less.html: ['.html']
          .less: ['.css']
    defaults:
      options:
        cleancss: false
        compress: false
targets:
  $default:
    builders:
      test_less_dart:
        options:
          entry_points: ['web/builder.less', 'web/test.less', '*.html']
          include_path: 'lib/lessIncludes'
 */

///
Builder lessCustomBuilder(BuilderOptions builderOptions) =>
    new LessCustomBuilder(new LessBuilderOptions(builderOptions));

///
class LessCustomBuilder extends LessBuilder {
  ///
  LessCustomBuilder(LessBuilderOptions options):super(options);

  @override
  void customOptions(LessOptions options) {
    options.definePlugin('myplugin', new MyPlugin()); //use @plugin "myplugin";  directive to load it
  }
}

///
class MyProcessor extends Processor {
  ///
  MyProcessor(PluginOptions options):super(options);

  @override
  String process(String input, Map<String, dynamic> options) =>
      '/* MyPlugin custom transformer post processor */\n$input';
}

///
class MyPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  ///
  MyPlugin(): super();

  @override
  void install(PluginManager pluginManager) {
    final Processor myProcessor = new MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}
