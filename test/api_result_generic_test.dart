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
        message: HttpMessage(
          title: 'Test Error',
          details: 'Test error details',
        ),
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
        message: HttpMessage(
          title: 'Original Error',
          details: 'Original details',
        ),
      );
      final result = ApiResult<int>.err(error);
      final transformed = result.map(
        (value) => value.toString(),
        (error) => ApiErr(
          message: HttpMessage(
            title: 'Transformed Error',
            details: 'Transformed: ${error.message?.details}',
          ),
        ),
      );

      expect(transformed.isErr, isTrue);
      expect(
        transformed.errorOrNull?.message?.title,
        equals('Transformed Error'),
      );
      expect(
        transformed.errorOrNull?.message?.details,
        contains('Original details'),
      );
    });
  });
}
