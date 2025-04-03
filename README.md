# Result Handler Library

A robust, functional error handling library for Dart and Flutter that provides a type-safe way to manage operations that can fail.

## Features

- Functional error handling with `Result<T, E>` pattern
- Comprehensive API error management
- Async and sync error handling
- Chainable operations
- Flexible error transformation

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  result_handler: ^latest_version
```

## Basic Usage

### Simple Result Handling

```dart
import 'package:result_handler/result_handler.dart';

// Safe division function
Result<double, String> divideNumbers(int a, int b) {
  if (b == 0) {
    return Err('Cannot divide by zero');
  }
  return Ok(a / b);
}

void main() {
  final result = divideNumbers(10, 2);
  
  result.when(
    ok: (value) => print('Result: $value'),
    err: (error) => print('Error: $error'),
  );
}
```

### API Error Handling

```dart
Future<void> fetchUserData(String userId) async {
  final response = await apiClient.get('/users/$userId');
  
  final userResult = response.toResult(User.fromJson);
  
  userResult.when(
    ok: (user) => displayUser(user),
    err: (apiError) => showErrorMessage(apiError.message),
  );
}
```

### Async Error Handling

```dart
Future<void> performAsyncOperation() async {
  final result = await Result.tryAsync(() async {
    // Some potentially failing async operation
    return await complexNetworkCall();
  });
  
  result.when(
    ok: (data) => processData(data),
    err: (error) => handleError(error),
  );
}
```

## Advanced Features

- Transform success values
- Chain operations
- Custom error mapping
- Recover from errors

## Contribution

Contributions are welcome! If you have ideas for new features or improvements, please open an [issue](https://github.com/JhonaCodes/multiselect_field/issues) or submit a pull request.

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.