# Result Controller Library

A robust, functional error handling library for Dart and Flutter that provides a type-safe way to manage operations that can fail. This library implements the Result/Either pattern for elegant error handling.

![result_controller](https://github.com/user-attachments/assets/35b03a5c-e2e9-4a99-8c56-aa6084e82066)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![result_controller](https://img.shields.io/pub/v/result_controller.svg)](https://pub.dev/packages/result_controller)
[![Dart 3](https://img.shields.io/badge/Dart-3%2B-blue.svg)](https://dart.dev/)
[![Flutter 3.10](https://img.shields.io/badge/Flutter-3%2B-blue.svg)](https://flutter.dev/)


## Features

- **Functional Error Handling**: Type-safe `Result<T, E>` pattern
- **Comprehensive API Error Management**: Specialized tools for API responses
- **Error Context Preservation**: Maintain stack traces and original errors
- **Chainable Operations**: Fluent API for sequential operations
- **Flexible Error Transformation**: Convert between error types
- **Async Support**: Handle both synchronous and asynchronous operations
- **JSON Processing Utilities**: Safely parse and transform JSON data

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  result_controller: ^1.0.2
```

## Basic Usage

### Core Result Type

The foundation of this library is the `Result<T, E>` type which represents either a successful value of type `T` or an error of type `E`.

```dart
import 'package:result_controller/result_controller.dart';

// Safe division function that can't throw exceptions
Result<double, String> divideNumbers(int a, int b) {
  if (b == 0) {
    return Err('Cannot divide by zero');
  }
  return Ok(a / b);
}

void main() {
  final result = divideNumbers(10, 2);
  
  // Handle both success and error cases
  result.when(
    ok: (value) => print('Result: $value'),  // Prints: Result: 5.0
    err: (error) => print('Error: $error'),
  );
  
  // Or extract the value directly (throws if it's an error)
  try {
    final value = result.data;
    print('Value: $value');  // Prints: Value: 5.0
  } catch (e) {
    print('Error accessing value: $e');
  }
}
```

### Wrapping Exceptions

Use the `trySync` method to safely execute code that might throw exceptions:

```dart
// This function safely parses an integer
Result<int, ResultError> parseInteger(String input) {
  return Result.trySync(() => int.parse(input));
}

// Usage
final result = parseInteger('42');
final invalidResult = parseInteger('not a number');

result.when(
  ok: (value) => print('Parsed: $value'),  // Prints: Parsed: 42
  err: (error) => print('Parse error: $error'),
);

invalidResult.when(
  ok: (value) => print('Parsed: $value'),
  err: (error) => print('Parse error: $error'),  // Prints details about the FormatException
);
```

### Transforming Results

Use `map` to transform the success value:

```dart
Result<int, String> getNumber() => Ok(10);

final stringResult = getNumber().map((number) => 'Number: $number');

stringResult.when(
  ok: (value) => print(value),  // Prints: Number: 10
  err: (error) => print('Error: $error'),
);
```

## API Response Handling

### ApiResponse Class

The `ApiResponse` class represents a response from an API operation, containing data, status code, and possible error information.

```dart
import 'package:result_controller/result_controller.dart';

// Create a successful response
final successResponse = ApiResponse.success(
  {'id': '123', 'name': 'John Doe'},
  statusCode: 200,
);

// Create an error response
final errorResponse = ApiResponse.failure(
  HttpError(
    exception: Exception('Network timeout'),
    stackTrace: StackTrace.current,
    data: HttpMessage(
      success: false,
      title: 'Connection Error',
      details: 'Could not connect to the server',
    ),
  ),
  statusCode: 503,
);
```

### Processing API Responses with when()

Use the `when()` method to handle both success and error cases:

```dart
ApiResponse response = await apiClient.get('/users/123');

final userName = response.when(
  ok: (data) => data['name'] as String,
  err: (error) => 'Unknown User',
);

print('User name: $userName');
```

### Processing Lists with whenList()

The `whenList()` method is specifically designed for API responses that contain lists of objects:

```dart
ApiResponse response = await apiClient.get('/users');

final users = response.whenList(
  ok: (usersList) => usersList.map((userData) => User.fromJson(userData)).toList(),
  err: (error) {
    logError('Failed to fetch users', error);
    return <User>[]; // Return empty list on error
  },
);

// Now we have a typed list of User objects
for (final user in users) {
  print('User: ${user.name}');
}
```

### Processing Typed Lists with whenListType()

Use `whenListType()` when working with lists of primitive types or mixed content:

```dart
ApiResponse response = await apiClient.get('/user/scores');

// Extract a list of integers from the response
final scores = response.whenListType<List<int>, int>(
  ok: (scoresList) => scoresList,  // We already have the correct type
  err: (error) => <int>[],
  filterNulls: true,  // Remove any null values from the list
);

final average = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
print('Average score: $average');
```

### Processing Dynamic JSON Maps with whenJsonListMap()

For handling complex, dynamic JSON structures:

```dart
ApiResponse response = await apiClient.get('/configurations');

final configs = response.whenJsonListMap(
  ok: (configList) => configList.map((config) {
    return UserConfiguration(
      id: config['id'],
      settings: config['settings'] ?? {},
    );
  }).toList(),
  err: (error) => <UserConfiguration>[],
);

// Process the configurations
for (final config in configs) {
  applyConfiguration(config);
}
```

### Converting ApiResponse to ApiResult

For more functional processing, convert to an `ApiResult`:

```dart
ApiResponse response = await apiClient.get('/users/123');

// Convert to ApiResult
ApiResult<User> result = response.toResult(User.fromJson);

// Process with functional style
result.when(
  ok: (user) => displayUserProfile(user),
  err: (error) => showErrorMessage(error.message?.details ?? 'Unknown error'),
);
```

### Converting List Responses

For list responses:

```dart
ApiResponse response = await apiClient.get('/posts');

// Convert list response to ApiResult
ApiResult<List<Post>> result = response.toListResult(
  (items) => items.map((item) => Post.fromJson(item)).toList(),
);

result.when(
  ok: (posts) => displayPosts(posts),
  err: (error) => showErrorMessage('Could not load posts'),
);
```

## Advanced Features

### Chaining Operations

Use `flatMap` to chain operations that might fail:

```dart
Future<Result<User, ApiErr>> fetchUser(String id) async {
  // Implementation details...
}

Future<Result<List<Post>, ApiErr>> fetchUserPosts(User user) async {
  // Implementation details...
}

// Chain operations
final postsResult = await fetchUser('123').flatMap((user) => fetchUserPosts(user));

postsResult.when(
  ok: (posts) => displayPosts(posts),
  err: (error) => showErrorMessage(error.message?.details ?? 'Unknown error'),
);
```

### Error Recovery

Use `recover` to handle errors and potentially recover from them:

```dart
Future<Result<List<Post>, ApiErr>> fetchPosts() async {
  // Implementation details...
}

// Try to fetch from network, fall back to cache on error
final posts = await fetchPosts().recover((error) {
  if (error.statusCode == 503) {
    // Network unavailable, try to load from cache
    return loadPostsFromCache();
  }
  // Any other error is propagated
  return Err(error);
});
```

### Error Transformation

Convert between error types with `mapError`:

```dart
Result<User, ApiErr> fetchResult = await fetchUser('123');

// Convert API errors to user-friendly messages
Result<User, String> userResult = fetchResult.mapError((apiErr) {
  if (apiErr.statusCode == 404) {
    return 'User not found';
  } else if (apiErr.statusCode == 401) {
    return 'You need to login first';
  }
  return 'An unexpected error occurred';
});
```

### Collection Operations

Special extensions for working with collections:

```dart
// Filter a list result
Result<List<Post>, ApiErr> postsResult = await fetchPosts();
Result<List<Post>, ApiErr> recentPosts = postsResult.filter((post) => 
  post.date.isAfter(DateTime.now().subtract(Duration(days: 7)))
);

// Transform each item in a list result
Result<List<Post>, ApiErr> postsResult = await fetchPosts();
Result<List<String>, ApiErr> postTitles = postsResult.mapEach((post) => post.title);
```

### Async Error Handling

Safe execution of async operations:

```dart
Future<void> performAsyncOperation() async {
  // Safely execute async code that might throw
  final result = await Result.tryAsync(() async {
    final response = await http.get(Uri.parse('https://api.example.com/data'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
    return json.decode(response.body);
  });
  
  result.when(
    ok: (data) => processData(data),
    err: (error) => displayError(error),
  );
}
```

### Custom Error Mapping

Transform exceptions to your domain-specific errors:

```dart
Future<Result<User, UserError>> fetchUser(String id) async {
  return Result.tryAsyncMap(
    () async {
      final response = await http.get(Uri.parse('https://api.example.com/users/$id'));
      if (response.statusCode != 200) {
        throw HttpException('Failed with status: ${response.statusCode}');
      }
      return User.fromJson(json.decode(response.body));
    },
    (error, stackTrace) {
      if (error is HttpException) {
        return UserError.network('Failed to connect: $error');
      } else if (error is FormatException) {
        return UserError.parsing('Invalid data format: $error');
      }
      return UserError.unknown('Unexpected error: $error');
    },
  );
}
```
### Complete API Client Example

Here's a more complete example showing how to use the Result Controller in an API client:

```dart
class ApiClient {
  final http.Client _client;
  final String _baseUrl;
  
  ApiClient(this._client, this._baseUrl);
  
  Future<ApiResponse> get(Params params) async {
    return Result.tryAsyncMap<ApiResponse, ApiResponse>(
      () async {
        final url = Uri.parse('$_baseUrl/${params.path}');
        final response = await _client.get(
          url,
          headers: params.header,
        );
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.success(
            response.body,
            statusCode: response.statusCode,
          );
        } else {
          // Parse error response
          HttpMessage? errorMessage;
          try {
            final errorData = json.decode(response.body);
            errorMessage = HttpMessage.fromJson(errorData);
          } catch (_) {
            errorMessage = HttpMessage(
              success: false,
              title: 'HTTP Error',
              details: 'Request failed with status: ${response.statusCode}',
            );
          }
          
          throw HttpError(
            exception: Exception('HTTP error ${response.statusCode}'),
            stackTrace: StackTrace.current,
            data: errorMessage,
          );
        }
      },
      (error, stackTrace) {
        // Convert any exception to a failure response
        return ApiResponse.failure(
          HttpError(
            exception: error,
            stackTrace: stackTrace,
            data: HttpMessage.fromException(error),
          ),
        );
      },
    );
  }
  
  // Similar implementations for post, put, delete, etc.
}

// Usage
Future<ApiResult<User>> fetchUser(String id) async {
  final response = await apiClient.get(
    Params(path: 'users/$id', header: {'Authorization': 'Bearer $token'}),
  );
  
  return response.toResult(User.fromJson);
}

// Using the API client
void main() async {
  final userResult = await fetchUser('123');
  
  userResult.when(
    ok: (user) => print('User: ${user.name}'),
    err: (error) => print('Error: ${error.message?.details}'),
  );
}
```

## Error Handling Strategy

The Result Controller library promotes a functional approach to error handling:

1. **Explicit Error Types**: All possible errors are represented in the return type
2. **No Surprise Exceptions**: Operations return errors rather than throwing exceptions
3. **Error Context Preservation**: Stack traces and original errors are maintained
4. **Composable Operations**: Chain operations together with proper error handling
5. **Typed Error Handling**: Different error types for different contexts

## Contribution

Contributions are welcome! If you have ideas for new features or improvements, please open an [issue](https://github.com/jhonacodes/result_controller/issues) or submit a pull request.

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
