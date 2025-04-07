import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

void main() {
  group('ApiResponse Headers Tests', () {
    test('headers are preserved in success response', () {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer token',
        'Custom-Header': 'value'
      };
      
      final response = ApiResponse.ok(
        {'data': 'value'}, 
        statusCode: 200, 
        headers: headers
      );
      
      expect(response.headers, equals(headers));
      expect(response.headers['Content-Type'], equals('application/json'));
    });
    
    test('headers are preserved in error response', () {
      final headers = {
        'Content-Type': 'application/json',
        'WWW-Authenticate': 'Bearer error="invalid_token"'
      };
      
      final response = ApiResponse.err(
        ApiErr(
          message: HttpMessage(title: 'Error', details: 'Details')
        ),
        statusCode: 401,
        headers: headers
      );
      
      expect(response.headers, equals(headers));
      expect(response.headers['WWW-Authenticate'], contains('invalid_token'));
    });
  });
} 