import 'package:result_controller/src/api_err_handler.dart';

/// Represents a response from an API operation
///
/// Provides a comprehensive and flexible way to handle API responses
/// with robust err management and type-safe data processing.
///
/// Key Features:
/// - Supports various data types (maps, lists, primitives)
/// - Type-safe data processing
/// - Comprehensive err handling
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
///   err: (err) => [],
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
  /// - 400-499: Client err
  /// - 500-599: Server err
  final int? statusCode;

  final Map<String, String> headers;

  /// Detailed err information if the API call failed
  ///
  /// Contains exception details, stack trace, and user-friendly err messages
  final ApiErr? err;

  /// Constructs an [ApiResponse] with optional data, status code, and err
  ///
  /// Allows flexible creation of API responses for different scenarios
  ///
  /// Parameters:
  /// - [statusCode]: HTTP status code of the response
  /// - [data]: Raw response data
  /// - [err]: Detailed err information
  ApiResponse({this.statusCode, this.data, this.err, Map<String, String>? headers }): headers = headers ?? {};

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
  factory ApiResponse.success(dynamic data, {int? statusCode, required Map<String, String> headers}) {
    return ApiResponse(data: data, statusCode: statusCode, headers: headers);
  }

  /// Creates an API response representing a failure
  ///
  /// Used when an API call encounters an err
  ///
  /// Parameters:
  /// - [err]: Detailed err information
  /// - [statusCode]: Optional HTTP status code
  ///
  /// Example:
  /// ```dart
  /// final response = ApiResponse.failure(
  ///   Httperr(
  ///     exception: Exception('Network err'),
  ///     data: HttpMessage(
  ///       success: false,
  ///       title: 'Connection err',
  ///       details: 'Could not connect to server'
  ///     )
  ///   ),
  ///   statusCode: 500
  /// );
  /// ```
  factory ApiResponse.failure(ApiErr err, {int? statusCode, required Map<String, String> headers}) {
    return ApiResponse(err: err, statusCode: statusCode, headers: headers,data: null);
  }

  /// Processes the response with separate handlers for success and err cases
  ///
  /// Provides a functional approach to handling API responses with flexible err management
  ///
  /// This method is useful when:
  /// - You need to process API responses with different outcomes
  /// - Want to handle success and err scenarios in a single call
  /// - Require type-safe err and success processing
  ///
  /// Parameters:
  /// - [ok]: Function to process successful data
  /// - [err]: Function to handle err
  ///
  /// Returns the result of processing the response based on its state
  ///
  /// Example:
  /// ```dart
  /// final userName = response.when(
  ///   ok: (data) => data['name'],
  ///   err: (err) => 'Unknown User'
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: Calls the [ok] function with response data
  /// - err response: Calls the [err] function with err details
  /// - Null data: Treats as an err condition
  T when<T>({
    required T Function(dynamic data) ok,
    required T Function(ApiErr err) err,
  }) {
    if (this.err != null) {
      return err(this.err!);
    }

    if (data == null) {
      return err(
        ApiErr(
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
  /// - [err]: Function to handle err
  ///
  /// Returns the result of processing the list
  ///
  /// Example:
  /// ```dart
  /// final users = response.whenList(
  ///   ok: (list) => list.map(User.fromJson).toList(),
  ///   err: (err) => [],
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: Converts list to [Map<String, dynamic>]
  /// - err response: Calls err handler
  /// - Non-list data: Treats as an err condition
  T whenList<T>({
    required T Function(List<Map<String, dynamic>> data) ok,
    required T Function(ApiErr err) err,
  }) {
    if (this.err != null) {
      return err(this.err!);
    }

    if (data == null) {
      return err(
        ApiErr(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    if (data is! List) {
      return err(
        ApiErr(
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
  /// - [err]: Function to handle err
  /// - [filterNulls]: Option to remove null values from the list
  ///
  /// Returns the result of processing the typed list
  ///
  /// Example:
  /// ```dart
  /// final numbers = response.whenListType(
  ///   ok: (list) => list,
  ///   err: (err) => [],
  ///   filterNulls: true,
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: Converts list to specified type
  /// - err response: Calls err handler
  /// - Non-list data: Treats as an err condition
  T whenListType<T, I>({
    required T Function(List<I> data) ok,
    required T Function(ApiErr err) err,
    bool filterNulls = false,
  }) {
    if (this.err != null) {
      return err(this.err!);
    }

    if (data == null) {
      return err(
        ApiErr(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    if (data is! List) {
      return err(
        ApiErr(
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
          ApiErr(
            exception: Exception('err converting item: $e'),
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
  /// - [err]: Function to handle errs
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
  ///   err: (err) => [], // Return empty list on err
  /// );
  /// ```
  ///
  /// Possible scenarios:
  /// - Successful response: List of maps with string keys and dynamic values
  /// - err response: Returns result of err handler
  /// - Invalid data: Throws format exception if data is not a list of maps
  T whenJsonListMap<T>({
    required T Function(List<Map<String, dynamic>> data) ok,
    required T Function(ApiErr err) err,
  }) {
    if (this.err != null) {
      return err(this.err!);
    }

    if (data == null) {
      return err(
        ApiErr(
          exception: Exception('No data in response'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    if (data is! List) {
      return err(
        ApiErr(
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
          ApiErr(
            exception: Exception('List contains non-map items'),
            stackTrace: StackTrace.current,
          ),
        );
      }
    }

    return ok(typedList);
  }
}
