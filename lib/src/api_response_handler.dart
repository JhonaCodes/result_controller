import 'package:result_controller/src/api_err_handler.dart';

/// Represents a response from an API operation
///
/// Provides a comprehensive and flexible way to handle API responses
/// with robust error management and type-safe data processing.
///
/// Key Features:
/// - Supports various data types (maps, lists, primitives)
/// - Type-safe data processing
/// - Comprehensive error handling
/// - Flexible response transformation methods
///
/// This class is designed to simplify API response parsing and
/// provide a consistent approach to handling different response scenarios.
///
/// Example Usage:
/// ```dart
/// ApiResponse response = await apiClient.get('/users');
///
/// final users = response.whenList(
///   ok: (list) => list.map(User.fromJson).toList(),
///   err: (error) => [],
/// );
/// ```
class ApiResponse {
  /// The raw response data from the API
  ///
  /// Can be of various types: Map, List, String, number,
  /// or any other JSON-compatible type.
  final dynamic data;

  /// The HTTP status code of the response
  ///
  /// Provides context about the request's outcome:
  /// - 200-299: Successful responses
  /// - 400-499: Client errors
  /// - 500-599: Server errors
  final int? statusCode;

  /// Detailed error information if the API call failed
  ///
  /// Contains exception details, stack trace, and user-friendly error messages
  final HttpError? error;

  /// Constructs an [ApiResponse] with optional data, status code, and error
  ///
  /// Allows flexible creation of API responses for different scenarios
  ///
  /// Parameters:
  /// - [statusCode]: HTTP status code of the response
  /// - [data]: Raw response data
  /// - [error]: Detailed error information
  ApiResponse({this.statusCode, this.data, this.error});

  /// Creates a successful API response
  ///
  /// Used when an API call completes successfully with data
  ///
  /// Parameters:
  /// - [data]: Successful response data
  /// - [statusCode]: Optional HTTP status code
  ///
  /// Example:
  /// ```dart
  /// final response = ApiResponse.success(
  ///   {'name': 'John', 'age': 30},
  ///   statusCode: 200
  /// );
  /// ```
  factory ApiResponse.success(dynamic data, {int? statusCode}) {
    return ApiResponse(data: data, statusCode: statusCode);
  }

  /// Creates an API response representing a failure
  ///
  /// Used when an API call encounters an error
  ///
  /// Parameters:
  /// - [error]: Detailed error information
  /// - [statusCode]: Optional HTTP status code
  ///
  /// Example:
  /// ```dart
  /// final response = ApiResponse.failure(
  ///   HttpError(
  ///     exception: Exception('Network error'),
  ///     data: HttpMessage(
  ///       success: false,
  ///       title: 'Connection Error',
  ///       details: 'Could not connect to server'
  ///     )
  ///   ),
  ///   statusCode: 500
  /// );
  /// ```
  factory ApiResponse.failure(HttpError error, {int? statusCode}) {
    return ApiResponse(error: error, statusCode: statusCode, data: null);
  }

  /// Processes the response with separate handlers for success and error cases
  ///
  /// Provides a functional approach to handling API responses with flexible error management
  ///
  /// This method is useful when:
  /// - You need to process API responses with different outcomes
  /// - Want to handle success and error scenarios in a single call
  /// - Require type-safe error and success processing
  ///
  /// Parameters:
  /// - [ok]: Function to process successful data
  /// - [err]: Function to handle errors
  ///
  /// Returns the result of processing the response based on its state
  ///
  /// Example:
  /// ```dart
  /// final userName = response.when(
  ///   ok: (data) => data['name'],
  ///   err: (error) => 'Unknown User'
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: Calls the [ok] function with response data
  /// - Error response: Calls the [err] function with error details
  /// - Null data: Treats as an error condition
  T when<T>({
    required T Function(dynamic data) ok,
    required T Function(HttpError error) err,
  }) {
    if (error != null) {
      return err(error!);
    }

    if (data == null) {
      return err(
        HttpError(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    return ok(data);
  }

  /// Processes a list response with flexible map conversion
  ///
  /// Converts the list to a list of [Map<String, dynamic>]
  ///
  /// This method is particularly useful when:
  /// - Dealing with API responses containing lists of objects
  /// - Need to standardize map structures
  /// - Handle different map input types
  ///
  /// Parameters:
  /// - [ok]: Function to process the converted list
  /// - [err]: Function to handle errors
  ///
  /// Returns the result of processing the list
  ///
  /// Example:
  /// ```dart
  /// final users = response.whenList(
  ///   ok: (list) => list.map(User.fromJson).toList(),
  ///   err: (error) => [],
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: Converts list to [Map<String, dynamic>]
  /// - Error response: Calls error handler
  /// - Non-list data: Treats as an error condition
  T whenList<T>({
    required T Function(List<Map<String, dynamic>> data) ok,
    required T Function(HttpError error) err,
  }) {
    if (error != null) {
      return err(error!);
    }

    if (data == null) {
      return err(
        HttpError(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    if (data is! List) {
      return err(
        HttpError(
          exception: Exception('Expected a list, got ${data.runtimeType}'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    // Convert to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> typedList = [];

    for (var item in data) {
      if (item is Map<String, dynamic>) {
        typedList.add(item);
      } else if (item is Map) {
        typedList.add(Map<String, dynamic>.from(item));
      }
    }

    return ok(typedList);
  }

  /// Processes a list response with type-specific conversion
  ///
  /// Allows converting a list to a specific type or handling mixed lists
  ///
  /// This method is useful when:
  /// - Need to convert list items to a specific type
  /// - Want to handle lists with mixed or dynamic content
  /// - Require flexible list transformation
  ///
  /// Parameters:
  /// - [ok]: Function to process the converted list
  /// - [err]: Function to handle errors
  /// - [filterNulls]: Option to remove null values from the list
  ///
  /// Returns the result of processing the typed list
  ///
  /// Example:
  /// ```dart
  /// final numbers = response.whenListType(
  ///   ok: (list) => list,
  ///   err: (error) => [],
  ///   filterNulls: true,
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: Converts list to specified type
  /// - Error response: Calls error handler
  /// - Non-list data: Treats as an error condition
  T whenListType<T, I>({
    required T Function(List<I> data) ok,
    required T Function(HttpError error) err,
    bool filterNulls = false,
  }) {
    if (error != null) {
      return err(error!);
    }

    if (data == null) {
      return err(
        HttpError(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    if (data is! List) {
      return err(
        HttpError(
          exception: Exception('Expected a list, got ${data.runtimeType}'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    // Convert to List<I>
    final List<I> typedList = [];

    for (var item in data) {
      try {
        // Attempt direct cast if possible
        final convertedItem = item is I ? item : null;

        if (convertedItem != null || !filterNulls) {
          typedList.add(convertedItem as I);
        }
      } catch (e) {
        return err(
          HttpError(
            exception: Exception('Error converting item: $e'),
            stackTrace: StackTrace.current,
          ),
        );
      }
    }

    return ok(typedList);
  }

  /// Processes a list of JSON maps with dynamic string keys
  ///
  /// Provides a comprehensive method to handle API responses that return
  /// lists of complex, dynamic JSON objects with string keys
  ///
  /// This method is particularly useful when dealing with:
  /// - Configuration lists
  /// - Dynamic report data
  /// - Flexible API responses with varying object structures
  ///
  /// Parameters:
  /// - [ok]: Function to process the list of JSON maps
  /// - [err]: Function to handle errors
  ///
  /// Returns the result of processing the list of maps
  ///
  /// Example:
  /// ```dart
  /// // Fetching a list of dynamic user configurations
  /// ApiResponse response = await apiClient.get(path: 'user/configurations');
  ///
  /// final configurations = response.whenJsonListMap(
  ///   ok: (configList) => configList.map((config) {
  ///     return UserConfiguration(
  ///       id: config['id'],
  ///       settings: config['settings'] ?? {},
  ///     );
  ///   }).toList(),
  ///   err: (error) => [], // Return empty list on error
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: List of maps with string keys and dynamic values
  /// - Error response: Returns result of error handler
  /// - Invalid data: Throws format exception if data is not a list of maps
  T whenJsonListMap<T>({
    required T Function(List<Map<String, dynamic>> data) ok,
    required T Function(HttpError error) err,
  }) {
    if (error != null) {
      return err(error!);
    }

    if (data == null) {
      return err(
        HttpError(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    if (data is! List) {
      return err(
        HttpError(
          exception: Exception('Expected a list, got ${data.runtimeType}'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    // Convert to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> typedList = [];

    for (var item in data) {
      if (item is Map<String, dynamic>) {
        typedList.add(item);
      } else if (item is Map) {
        typedList.add(Map<String, dynamic>.from(item));
      } else {
        return err(
          HttpError(
            exception: Exception('List contains non-map items'),
            stackTrace: StackTrace.current,
          ),
        );
      }
    }

    return ok(typedList);
  }
}
