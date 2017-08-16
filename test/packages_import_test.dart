import 'dart:async';
import 'dart:io';
import 'package:less_dart/src/environment/package_resolver_provider.dart';
import 'package:less_dart/transformer.dart';
import 'package:mockito/mockito.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:test/test.dart';

void main() {
  packagesImportTest();
}

/// packagesImportTest
void packagesImportTest() {
  group('packages_import', () {
    setUp(() {});

    test('properly converts packages/ path in import', () async {
      final String parentFolder = Directory.current.path;
      final String packagesFileContent = 'test_package:file://$parentFolder';
      final String lessPostfix = 'test/less/import-packages/test.less';
      final PackageResolver _resolver = await PackageResolver.loadConfig(new Uri.dataFromString(packagesFileContent));
      final PackageResolverProviderMock _packageResolverProviderMock = new PackageResolverProviderMock();
      when(_packageResolverProviderMock.getPackageResolver()).thenReturn(new Future<PackageResolver>.value(_resolver));
      final FileFileManager _fileManager = new FileFileManager(new Environment(), _packageResolverProviderMock);
      final FileLoaded result = await _fileManager.loadFile('packages/test_package/$lessPostfix', '.', null, null);
      expect(result.filename == '$parentFolder/$lessPostfix', true);
    });
  });
}

/// PackageResolverProviderMock
class PackageResolverProviderMock extends Mock implements PackageResolverProvider {}
