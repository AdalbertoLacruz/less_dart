import 'package:unittest/unittest.dart';

import '../lib/src/cleancss_options.dart';
import '../lib/src/logger.dart';

main(){
  SimpleConfiguration config = new SimpleConfiguration();
  config.throwOnTestFailures = false;
  config.stopTestOnExpectFailure = false;
  unittestConfiguration = config;

  cleancss_options_test();
}

cleancss_options_test(){
  group('cleancss_options', () {
      int testCount = 0;
      bool result;
      CleancssOptions cleancssOptions;

      setUp((){
        cleancssOptions = new CleancssOptions();
      });

      tearDown((){
        testCount++;
        if(testCount == testCases.length) print('stderr: ${new Logger().stderr.toString()}');
      });

      test('--keep-line-breaks', (){
        result = cleancssOptions.parse('--keep-line-breaks');
        expect(result, true);
        expect(cleancssOptions.keepBreaks, true);
      });

      test('-b', (){
        result = cleancssOptions.parse('-b');
        expect(result, true);
        expect(cleancssOptions.keepBreaks, true);
      });

      test('--s0', (){
        result = cleancssOptions.parse('--s0');
        expect(result, true);
        expect(cleancssOptions.keepSpecialComments, equals(0));
      });

      test('--s1', (){
        result = cleancssOptions.parse('--s1');
        expect(result, true);
        expect(cleancssOptions.keepSpecialComments, equals(1));
      });

      test('--skip-advanced', (){
        result = cleancssOptions.parse('--skip-advanced');
        expect(result, true);
        expect(cleancssOptions.noAdvanced, true);
      });

      test('--advanced', (){
        result = cleancssOptions.parse('--advanced');
        expect(result, true);
        expect(cleancssOptions.noAdvanced, false);
      });

      test('--compatibility', (){
        result = cleancssOptions.parse('--compatibility:ie7');
        expect(result, true);
        expect(cleancssOptions.compatibility, equals('ie7'));
      });

      test('--rounding-precision', (){
        result = cleancssOptions.parse('--rounding-precision:2');
        expect(result, true);
        expect(cleancssOptions.roundingPrecision, equals(2));
      });

      //check errors

      test('no arguments', (){
        result = cleancssOptions.parse(null);
        expect(result, false);
      });

      test('blank argument', (){
        result = cleancssOptions.parse('');
        expect(result, false);
      });

      test('--compatibility no argument', (){
        result = cleancssOptions.parse('--compatibility:');
        expect(result, false);
      });

      test('--rounding-precision no argument', (){
        result = cleancssOptions.parse('--rounding-precision:');
        expect(result, false);
      });
    });
}