import 'api_err_handler.dart';
import 'api_handler.dart';
/// ApiResponse class that integrates with the Result pattern
///
/// This class provides a lightweight container for API operation results,
/// holding either successful response data or error information. It serves
/// as a bridge between low-level HTTP operations and the higher-level
/// ApiResult functional error handling.
///
/// Example:
/// ```dart
/// // Create ApiResponse from a raw HTTP response
/// Future<ApiResponse> fetchUserData(String userId) async {
///   try {
///     final response = await http.get(
///       Uri.parse('https://api.example.com/users/$userId'),
///       headers: {'Authorization': 'Bearer $token'},
///     );
///
///     if (response.statusCode >= 200 && response.statusCode < 300) {
///       // Success case
///       return ApiResponse.success(
///         jsonDecode(response.body),
///         statusCode: response.statusCode,
///       );
///     } else {
///       // Error case with HTTP status code
///       return ApiResponse.failure(
///         HttpError(
///           exception: Exception('HTTP error ${response.statusCode}'),
///           stackTrace: StackTrace.current,
///           data: _parseErrorMessage(response.body),
///         ),
///         statusCode: response.statusCode,
///       );
///     }
///   } catch (e, stackTrace) {
///     // Network or parsing error
///     return ApiResponse.failure(
///       HttpError(
///         exception: e,
///         stackTrace: stackTrace,
///         data: HttpMessage(
///           success: false,
///           title: 'Connection Error',
///           details: 'Failed to connect to the server'
///         ),
///       ),
///     );
///   }
/// }
/// ```
class ApiResponse {
  /// The response data for successful API calls
  ///
  /// This can be any type depending on the API response format,
  /// typically a Map<String, dynamic> parsed from JSON or a List.
  final dynamic data;

  /// HTTP status code of the response
  ///
  /// Common values:
  /// - 200: OK
  /// - 201: Created
  /// - 204: No Content
  /// - 400: Bad Request
  /// - 401: Unauthorized
  /// - 404: Not Found
  /// - 500: Internal Server Error
  final int? statusCode;

  /// Error details if the API call failed
  ///
  /// This will be null for successful responses and populated
  /// with error information for failures.
  final HttpError? error;

  /// Creates a new ApiResponse
  ///
  /// This general constructor allows setting all properties directly.
  /// Usually, the factory constructors [ApiResponse.success] and
  /// [ApiResponse.failure] are more convenient.
  ApiResponse({this.statusCode, this.data, this.error});

  /// Creates an ApiResponse indicating success
  ///
  /// Use this constructor when an API call succeeds to wrap the
  /// response data and status code.
  ///
  /// Example:
  /// ```dart
  /// final jsonData = jsonDecode(response.body);
  /// return ApiResponse.success(
  ///   jsonData,
  ///   statusCode: response.statusCode,
  /// );
  /// ```
  factory ApiResponse.success(dynamic data, {int? statusCode}) {
    return ApiResponse(
      data: data,
      statusCode: statusCode,
    );
  }

  /// Creates an ApiResponse indicating failure
  ///
  /// Use this constructor when an API call fails to wrap the
  /// error information and status code.
  ///
  /// Example:
  /// ```dart
  /// return ApiResponse.failure(
  ///   HttpError(
  ///     exception: Exception('Network timeout'),
  ///     stackTrace: StackTrace.current,
  ///     data: HttpMessage(
  ///       success: false,
  ///       title: 'Connection Error',
  ///       details: 'Request timed out'
  ///     ),
  ///   ),
  ///   statusCode: null, // No status code for network error
  /// );
  /// ```
  factory ApiResponse.failure(HttpError error, {int? statusCode}) {
    return ApiResponse(
      error: error,
      statusCode: statusCode,
      data: null,
    );
  }

  /// Handles this response by applying the appropriate function
  ///
  /// Similar to the Result.when pattern, this allows processing both
  /// success and error cases with a single function call.
  ///
  /// Example:
  /// ```dart
  /// final userInfo = apiResponse.when(
  ///   ok: (data) {
  ///     // Process the successful data
  ///     final Map<String, dynamic> userData = data;
  ///     return User.fromJson(userData);
  ///   },
  ///   err: (error) {
  ///     // Handle the error
  ///     print('Error fetching user: ${error.data?.details}');
  ///     return User.empty(); // Return a default user
  ///   },
  /// );
  /// ```
  T when<T>({
    required T Function(dynamic data) ok,
    required T Function(HttpError error) err,
  }) {
    if (error != null) {
      return err(error!);
    }
    return ok(data);
  }

  /// Processes a response that contains a list
  ///
  /// This is a specialized version of [when] designed for handling
  /// API responses that should contain a list of items.
  /// It performs type checking and safely converts the data to the
  /// expected format.
  ///
  /// Example:
  /// ```dart
  /// final usersList = apiResponse.whenList(
  ///   ok: (userDataList) {
  ///     // Process the list of user data
  ///     return userDataList
  ///         .map((userData) => User.fromJson(userData))
  ///         .toList();
  ///   },
  ///   err: (error) {
  ///     // Handle the error
  ///     print('Error fetching users: ${error.data?.details}');
  ///     return <User>[]; // Return an empty list
  ///   },
  /// );
  /// ```
  T whenList<T, I>({
    required T Function(List<Map<String, dynamic>> data) ok,
    required T Function(HttpError error) err,
  }) {
    if (error != null) {
      return err(error!);
    }

    if (data is List) {
      try {
        final List<Map<String, dynamic>> typedList = data.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            throw FormatException('List item is not a Map<String, dynamic>');
          }
        }).toList();
        return ok(typedList);
      } catch (e, stack) {
        return err(HttpError(
          exception: e,
          stackTrace: stack,
          data: HttpMessage.fromException(e),
        ));
      }
    }

    return err(HttpError(
      exception: Exception('Data is not a list'),
      stackTrace: StackTrace.current,
      data: HttpMessage(
        success: false,
        title: 'Format Error',
        details: 'Expected a list but received a different type',
      ),
    ));
  }
}