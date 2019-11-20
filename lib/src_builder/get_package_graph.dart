import 'package:build_runner_core/build_runner_core.dart';

PackageGraph _packageGraph;

///
PackageGraph getPackageGraph() => _packageGraph ??= PackageGraph.forThisPackage();
