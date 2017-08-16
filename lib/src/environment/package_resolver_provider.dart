import 'dart:async';
import 'package:package_resolver/package_resolver.dart';

/// Package Resolver provider
class PackageResolverProvider {
  PackageResolver _packageResolver;

  /// get PackageResolver instance
  Future<PackageResolver> getPackageResolver() async {
    _packageResolver = _packageResolver?? await PackageResolver.loadConfig(new Uri.file('.packages'));
    return _packageResolver;
  }
}