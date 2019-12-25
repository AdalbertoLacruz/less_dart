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
      final uriParentFolder = Directory.current.uri;
      // something like: 'test_package:file:///c:/dart/less_dart/' for windows & linux
      final packagesFileContent = 'test_package:${uriParentFolder.toString()}';
      final lessRelativePath = 'test/less/import-packages/test.less';
      final lessAbsolutePath =
          uriParentFolder.resolve(lessRelativePath).toFilePath();

      final _resolver = await PackageResolver.loadConfig(
          Uri.dataFromString(packagesFileContent));
      final _packageResolverProviderMock = PackageResolverProviderMock();
      // when(_packageResolverProviderMock.getPackageResolver()).thenReturn(Future<PackageResolver>.value(_resolver));
      when(_packageResolverProviderMock.getPackageResolver())
          .thenAnswer((_) => Future<PackageResolver>.value(_resolver));

      final _fileManager =
          FileFileManager(Environment(), _packageResolverProviderMock);
      final result = await _fileManager.loadFile(
          'packages/test_package/$lessRelativePath', '.', null, null);
      expect(result.filename == lessAbsolutePath, true);
    });
  });
}

/// PackageResolverProviderMock
class PackageResolverProviderMock extends Mock
    implements PackageResolverProvider {}
