import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

void main() {
  group('Concurrency Tests', () {
    test('handles multiple async operations', () async {
      final futures = List.generate(10, (index) {
        return Result.tryAsyncMap<int, ApiErr>(() async {
          await Future.delayed(Duration(milliseconds: index * 10));
          return index;
        }, (error, stack) => ApiErr());
      });

      final results = await Future.wait(futures);

      expect(results.length, equals(10));
      expect(results.every((r) => r.isOk), isTrue);
      expect(
        results.map((r) => r.data).toList(),
        equals(List.generate(10, (i) => i)),
      );
    });

    test('handles concurrent error recovery', () async {
      final futures = List.generate(10, (index) async {
        final result = await Result.tryAsyncMap<int, ApiErr>(
          () async {
            await Future.delayed(Duration(milliseconds: index * 10));
            if (index % 2 == 0) throw Exception('Error $index');
            return index;
          },
          (error, stack) => ApiErr(
            message: HttpMessage(title: 'Error', details: error.toString()),
          ),
        );

        return result.recover((error) => Ok(index * 2));
      });

      final results = await Future.wait(futures);

      expect(results.length, equals(10));
      expect(results.every((r) => r.isOk), isTrue);
    });
  });
}
