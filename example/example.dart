import 'dart:developer';
import 'package:result_controller/result_controller.dart';

/// Simple User model for examples
class User {
  final String id;
  final String name;
  final int age;

  User({required this.id, required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, age: $age)';
}

void main() {
  log('=== Result Controller Examples ===\n');

  // Basic Result examples
  basicResultExamples();

  // API Result examples
  apiResultExamples();

  // Advanced patterns
  advancedPatterns();
}

/// Basic Result pattern examples
void basicResultExamples() {
  log('--- Basic Result Examples ---');

  // Example 1: Safe division
  log('\n1. Safe Division:');

  Result<double, String> safeDivide(double a, double b) {
    if (b == 0) {
      return Err('Cannot divide by zero');
    }
    return Ok(a / b);
  }

  // Success case
  final result1 = safeDivide(10, 2);
  result1.when(
    ok: (value) => log('  10 ÷ 2 = $value'),
    err: (error) => log('  Error: $error'),
  );

  // Error case
  final result2 = safeDivide(10, 0);
  result2.when(
    ok: (value) => log('  10 ÷ 0 = $value'),
    err: (error) => log('  Error: $error'),
  );

  // Example 2: Transforming results
  log('\n2. Transforming Results:');

  final doubled = result1.map((value) => value * 2);
  doubled.when(
    ok: (value) => log('  Doubled result: $value'),
    err: (error) => log('  Error: $error'),
  );

  // Example 3: Chaining operations
  log('\n3. Chaining Operations:');

  final chained = safeDivide(
    20,
    4,
  ).flatMap((value) => safeDivide(value, 2)).map((value) => value.toInt());

  chained.when(
    ok: (value) => log('  20 ÷ 4 ÷ 2 = $value'),
    err: (error) => log('  Error: $error'),
  );
}

/// API Result examples
void apiResultExamples() {
  log('\n--- API Result Examples ---');

  // Example 1: Creating ApiResult from JSON
  log('\n1. Creating User from JSON:');

  final userJson = {'id': '123', 'name': 'Alice', 'age': 25};

  final userResult = ApiResult.fromJson(
    data: userJson,
    onData: (json) => User.fromJson(json),
    statusCode: 200,
  );

  userResult.when(
    ok: (user) => log('  Created: $user'),
    err: (error) => log('  Error: ${error.msm}'),
  );

  // Example 2: Creating ApiResult from list
  log('\n2. Creating Users from JSON List:');

  final usersJson = [
    {'id': '1', 'name': 'Bob', 'age': 30},
    {'id': '2', 'name': 'Carol', 'age': 28},
  ];

  final usersResult = ApiResult.fromJsonList(
    data: usersJson,
    onData: (jsonList) => jsonList.map((json) => User.fromJson(json)).toList(),
    statusCode: 200,
  );

  usersResult.when(
    ok: (users) => log(
      '  Created ${users.length} users: ${users.map((u) => u.name).join(', ')}',
    ),
    err: (error) => log('  Error: ${error.msm}'),
  );

  // Example 3: Handling API errors
  log('\n3. Handling API Errors:');

  final errorResult = ApiResult<String>.err(
    ApiErr(
      title: 'Network Error',
      msm: 'Connection timeout',
      exception: Exception('Timeout after 30s'),
      stackTrace: StackTrace.current,
    ),
    statusCode: 408,
  );

  errorResult.when(
    ok: (data) => log('  Data: $data'),
    err: (error) => log(
      '  ${error.title}: ${error.msm} (Status: ${errorResult.statusCode})',
    ),
  );
}

/// Advanced usage patterns
void advancedPatterns() {
  log('\n--- Advanced Patterns ---');

  // Example 1: Error recovery
  log('\n1. Error Recovery:');

  Result<int, String> parseNumber(String input) {
    final parsed = int.tryParse(input);
    if (parsed == null) {
      return Err('Invalid number: $input');
    }
    return Ok(parsed);
  }

  final recovered = parseNumber(
    'invalid',
  ).recover((error) => parseNumber('42')); // Fallback to default

  recovered.when(
    ok: (value) => log('  Recovered value: $value'),
    err: (error) => log('  Recovery failed: $error'),
  );

  // Example 2: Working with collections
  log('\n2. Processing Collections:');

  final numbers = ['1', '2', 'invalid', '4'];
  final results = numbers.map(parseNumber).toList();

  // Separate success and errors
  final successes = results.where((r) => r.isOk).map((r) => r.data).toList();
  final errors = results
      .where((r) => r.isErr)
      .map((r) => r.errorOrNull)
      .toList();

  log('  Valid numbers: $successes');
  log('  Errors: $errors');

  // Example 3: Default values
  log('\n3. Default Values:');

  final invalidResult = parseNumber('invalid');
  final withDefault = invalidResult.getOrDefault(0);
  final withElse = invalidResult.getOrElse((error) => -1);

  log('  With default (0): $withDefault');
  log('  With else (-1): $withElse');

  // Example 4: Type transformations
  log('\n4. Type Transformations:');

  final stringResult = parseNumber('42').map((number) => 'Number: $number');
  stringResult.when(
    ok: (str) => log('  Transformed: $str'),
    err: (error) => log('  Error: $error'),
  );

  // Example 5: Error mapping
  log('\n5. Error Mapping:');

  final mappedError = parseNumber(
    'invalid',
  ).mapError((error) => 'USER_ERROR: $error');

  mappedError.when(
    ok: (value) => log('  Value: $value'),
    err: (error) => log('  Mapped error: $error'),
  );
}
