import 'dart:async';
import 'dart:developer';
import 'package:result_controller/result_controller.dart';

// Example model class
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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'age': age};
}

void main() {
  // Demonstrating basic Result usage
  demonstrateBasicResult();

  // Showcasing API error handling
  demonstrateApiErrorHandling();

  // Async error handling example
  demonstrateAsyncErrorHandling();
}

/// Demonstrates basic Result pattern for error handling
void demonstrateBasicResult() {
  log('\n--- Basic Result Handling ---');

  // Safe division with Result
  Result<double, String> divideNumbers(int a, int b) {
    if (b == 0) {
      return Err('Cannot divide by zero');
    }
    return Ok(a / b);
  }

  // Successful division
  final successResult = divideNumbers(10, 2);
  successResult.when(
    ok: (value) => log('Division result: $value'),
    err: (error) => log('Error: $error'),
  );

  // Failed division
  final failureResult = divideNumbers(10, 0);
  failureResult.when(
    ok: (value) => log('Division result: $value'),
    err: (error) => log('Error: $error'),
  );

  // Transforming results
  final transformedResult = successResult.map((value) => value * 2);
  transformedResult.when(
    ok: (value) => log('Transformed result: $value'),
    err: (error) => log('Error: $error'),
  );
}

/// Demonstrates API-specific error handling
void demonstrateApiErrorHandling() {
  log('\n--- API Error Handling ---');

  // Simulated API response
  Future<ApiResponse> fetchUserData(String userId) async {
    // Simulate network request
    await Future.delayed(Duration(milliseconds: 100));

    // Simulating different scenarios
    if (userId == 'error') {
      return ApiResponse.failure(
        HttpErr(
          exception: Exception('Network error'),
          stackTrace: StackTrace.current,
          data: HttpMessage(
            success: false,
            title: 'Connection Error',
            details: 'Could not connect to the server',
          ),
        ),
        statusCode: 500,
      );
    }

    // Successful response
    return ApiResponse.success({
      'id': userId,
      'name': 'John Doe',
      'age': 30,
    }, statusCode: 200);
  }

  // Fetch and process user data
  Future<void> processUser(String userId) async {
    final response = await fetchUserData(userId);

    final userResult = response.toResult(User.fromJson);

    userResult.when(
      ok: (user) => log('User fetched: ${user.name}, Age: ${user.age}'),
      err: (apiError) {
        log('API Error: ${apiError.message?.title}');
        log('Details: ${apiError.message?.details}');
      },
    );
  }

  // Process successful user fetch
  processUser('123');

  // Process user fetch with error
  processUser('error');
}

/// Demonstrates async error handling with Result
void demonstrateAsyncErrorHandling() {
  log('\n--- Async Error Handling ---');

  // Async operation that might fail
  Future<Result<String, String>> fetchData() async {
    try {
      // Simulate network request
      await Future.delayed(Duration(milliseconds: 100));

      // Simulate random failure
      if (DateTime.now().millisecondsSinceEpoch.isEven) {
        return Err('Random network error');
      }

      return Ok('Successful data fetch');
    } catch (e) {
      return Err('Failed to fetch data: ${e.toString()}');
    }
  }

  // Using tryAsync for safe async operations
  Future<void> safeDataFetch() async {
    final result = await Result.tryAsync(() async {
      await Future.delayed(Duration(milliseconds: 100));
      return 'Complex async operation';
    });

    result.when(
      ok: (data) => log('Async operation succeeded: $data'),
      err: (error) => log('Async operation failed: ${error.error}'),
    );
  }

  // Chaining async operations
  Future<void> chainedAsyncOperations() async {
    final result = await fetchData().flatMap((data) async {
      // Simulate further processing
      await Future.delayed(Duration(milliseconds: 50));
      return Ok('Processed: $data');
    });

    result.when(
      ok: (processedData) => log('Chained operation: $processedData'),
      err: (error) => log('Chained operation failed: $error'),
    );
  }

  // Run async examples
  safeDataFetch();
  chainedAsyncOperations();
}
