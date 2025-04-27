import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

void main() {
  group('ApiResult Generic Tests', () {
    test('ApiResult.ok creates successful result', () {
      final result = ApiResult<String>.ok('test');

      expect(result.isOk, isTrue);
      expect(result.data, equals('test'));
      expect(result.errorOrNull, isNull);
    });

    test('ApiResult.err creates error result', () {
      final error = ApiErr(
        title: 'Test Error',
        msm: 'Test error details',
      );
      final result = ApiResult<String>.err(error);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, equals(error));
      expect(() => result.data, throwsStateError);
    });

    test('ApiResult handles null values correctly', () {
      final result = ApiResult<String?>.ok(null);

      expect(result.isOk, isTrue);
      expect(result.data, isNull);
      expect(result.errorOrNull, isNull);
    });

    test('ApiResult preserves type information', () {
      final result = ApiResult<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.data, isA<int>());
      expect(result.data, equals(42));
    });

    test('ApiResult.map transforms success value', () {
      final result = ApiResult<int>.ok(42);
      final transformed = result.map(
            (value) => value.toString(),
            (error) => error,
      );

      expect(transformed.isOk, isTrue);
      expect(transformed.data, equals('42'));
    });

    test('ApiResult.map transforms error value', () {
      final error = ApiErr(
        title: 'Original Error',
        msm: 'Original details',
      );
      final result = ApiResult<int>.err(error);
      final transformed = result.map(
            (value) => value.toString(),
            (error) => ApiErr(
          title: 'Transformed Error',
          msm: 'Transformed: ${error.msm}',
        ),
      );

      expect(transformed.isErr, isTrue);
      expect(
        transformed.errorOrNull?.title,
        equals('Transformed Error'),
      );
      expect(
        transformed.errorOrNull?.msm,
        contains('Original details'),
      );
    });
  });
}