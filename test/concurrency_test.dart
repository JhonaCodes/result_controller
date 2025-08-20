import 'package:test/test.dart';
import 'package:result_controller/result_controller.dart';

void main() {
  group('Concurrency Tests', () {
    test('handles multiple async operations', () async {
      final futures = List.generate(10, (index) async {
        await Future.delayed(Duration(milliseconds: index * 10));
        return Ok<int, ApiErr>(index);
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
        await Future.delayed(Duration(milliseconds: index * 10));
        if (index % 2 == 0) {
          return Err<int, ApiErr>(ApiErr(title: 'Error', msm: 'Error $index'));
        }
        return Ok<int, ApiErr>(index);
      });

      final results = await Future.wait(futures);
      final recovered = results.map((r) {
        return r.recover((error) => Ok(int.parse(error.msm!.split(' ').last) * 2));
      }).toList();

      expect(recovered.length, equals(10));
      expect(recovered.every((r) => r.isOk), isTrue);
    });
  });
}