import 'dart:async';
import 'dart:io';

import 'package:less_dart/src/environment/environment.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  packagesImportTest();
}

/// packagesImportTest
void packagesImportTest() {
  group('packages_import', () {
    setUp(() {});

    test('properly converts packages/ path in import', () async {
      final Uri uriParentFolder = Directory.current.uri;
      // something like: 'test_package:file:///c:/dart/less_dart/' for windows & linux
      final String packagesFileContent = 'test_package:${uriParentFolder.toString()}';
      final String lessRelativePath = 'test/less/import-packages/test.less';
      final String lessAbsolutePath = uriParentFolder.resolve(lessRelativePath).toFilePath();

      final PackageResolver _resolver = await PackageResolver.loadConfig(Uri.dataFromString(packagesFileContent));
      final PackageResolverProviderMock _packageResolverProviderMock = PackageResolverProviderMock();
      when(_packageResolverProviderMock.getPackageResolver()).thenReturn(Future<PackageResolver>.value(_resolver));

      final FileFileManager _fileManager = FileFileManager(Environment(), _packageResolverProviderMock);
      final FileLoaded result = await _fileManager.loadFile('packages/test_package/$lessRelativePath', '.', null, null);
      expect(result.filename == lessAbsolutePath, true);
    });
  });
}

/// PackageResolverProviderMock
class PackageResolverProviderMock extends Mock implements PackageResolverProvider {}
