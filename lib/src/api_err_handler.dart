import 'package:result_controller/result_controller.dart';

/// Represents a detailed error originating from an API interaction.
///
/// Extends [ResultErr] to provide API-specific error details like HTTP status codes,
/// validation messages, and the original exception. It supports registering
/// error templates for different error types and contexts, allowing for
/// centralized and consistent error handling.
///
/// Type parameter [E] represents the type used for categorizing errors (e.g., an enum like `HttpError`).
///
class ApiErr<E> extends ResultErr<E> {

  // --- Properties ---

  /// Optional field-specific validation errors, often from form submissions (e.g., {'email': 'Invalid format'}).
  final Map<String, String>? validations;

  /// The original exception object that triggered this error (e.g., DioException, SocketException).
  final Object? exception;

  /// HTTP status code associated with the API error response (e.g., 400, 401, 404, 500).
  final int? statusCode;

  /// A structured, user-facing message providing context about the error.
  final HttpMessage? message;

  // --- Constructor ---

  /// Constructs a new [ApiErr] instance.
  ///
  /// The base error message for [ResultErr] is derived from [message.details] if provided,
  /// otherwise defaults to the string representation of the [exception], or a generic message.
  ///
  /// Parameters:
  ///   * [statusCode] - HTTP status code associated with the error.
  ///   * [exception] - The original exception that triggered this error.
  ///   * [message] - Structured user-facing error message with title and details.
  ///   * [validations] - Field-specific validation errors map.
  ///   * [stackTrace] - Stack trace from when the error occurred.
  ///   * [errorType] - The categorized error type (of type [E]) for identification.
  ///
  /// Example:
  /// ```dart
  /// final apiError = ApiErr<NetworkErrorType>(
  ///   statusCode: 503,
  ///   exception: SocketException('Service Unavailable'),
  ///   message: HttpMessage(
  ///     title: 'Service Down',
  ///     details: 'The server is temporarily unavailable. Please try again later.',
  ///   ),
  ///   errorType: NetworkErrorType.serviceUnavailable,
  ///   stackTrace: StackTrace.current,
  /// );
  /// ```
  ApiErr({
    this.statusCode,
    this.exception,
    this.message,
    this.validations,
    StackTrace? stackTrace,
    E? errorType
  }) : super(
    // Use message details, fallback to exception string, then to generic message
      message?.details ?? exception?.toString() ?? 'Unknown API error',
      stackTrace: stackTrace,
      type: errorType // Pass the error type to the base class
  );

  // --- toString Implementation ---

  /// Returns a human-readable string representation of the API error.
  ///
  /// Includes status code, error title/details from [message], or the exception string.
  /// Optionally includes the stack trace if provided.
  ///
  /// Example:
  /// ```dart
  /// print(ApiErr<HttpError>(
  ///   statusCode: 400,
  ///   errorType: HttpError.badRequest,
  ///   message: HttpMessage(
  ///     title: 'Bad Request',
  ///     details: 'Invalid email address provided.',
  ///   ),
  /// ));
  /// // Output: "Code: 400 Bad Request: Invalid email address provided."
  ///
  /// print(ApiErr<NetworkErrorType>(
  ///   errorType: NetworkErrorType.timeout,
  ///   exception: TimeoutException('Connection timed out'),
  /// ));
  /// // Output: "Error: Connection timed out"
  /// ```
  @override
  String toString() {
    final parts = <String>[];

    // Prefer structured message if available
    if (message != null) {
      parts.add('${message!.title}: ${message!.details}');
    } else if (exception != null) {
      // Format exception message cleanly
      final exceptionString = exception is Exception
          ? (exception as Exception).toString()
          : exception.toString();
      parts.add('Error: $exceptionString');
    } else {
      parts.add('Unknown API error${statusCode != null ? " (Code: $statusCode)" : ""}');
    }

    // Optionally add validation errors
    if (validations != null && validations!.isNotEmpty) {
      parts.add('Validations: ${validations.toString()}');
    }

    final result = parts.join(' | ');

    // Add stack trace if available
    if (stackTrace != null) {
      // Include basic info even with stack trace for context
      return '$result\n\nStackTrace:\n$stackTrace';
      // Alternative: return '$statusCode\n$type\n$result\n\nStackTrace:\n$stackTrace';
    }

    return result;
  }

  // --- Static Error Registry ---

  /// Stores mappings of error types and complex keys ([_StatusTypeKey]) to predefined [ApiErr] templates.
  /// This single map holds registrations for both simple type lookups and complex context-based lookups.
  static final Map<dynamic, ApiErr> _errorRegistry = {};

  // --- Static Registration Methods ---

  /// Registers a single error type-to-[ApiErr] template mapping.
  ///
  /// Use this for simple, direct mappings based on the error category ([exceptionType]).
  /// These templates are used by [fromExceptionType] and as a fallback by [fromStatusAndType].
  ///
  /// Example:
  /// ```dart
  /// // Assuming HttpError is an enum
  /// ApiErr.registerExceptionType<HttpError>(
  ///   HttpError.notFound,
  ///   ApiErr<HttpError>(
  ///     statusCode: 404, // Default status for this type
  ///     errorType: HttpError.notFound,
  ///     message: HttpMessage(
  ///       title: 'Not Found',
  ///       details: 'The requested resource could not be found.',
  ///     ),
  ///   )
  /// );
  /// ```
  static void registerExceptionType<T>(T exceptionType, ApiErr errorTemplate) {
    _errorRegistry[exceptionType] = errorTemplate;
  }

  /// Registers multiple error type-to-[ApiErr] template mappings at once.
  ///
  /// A convenience method for bulk registration of simple type mappings.
  ///
  /// Example:
  /// ```dart
  /// ApiErr.registerAllExceptionTypes<HttpError>({
  ///   HttpError.timeout: ApiErr<HttpError>(
  ///     statusCode: 408,
  ///     errorType: HttpError.timeout,
  ///     message: HttpMessage(title: 'Timeout', details: 'Request timed out.'),
  ///   ),
  ///   HttpError.unauthorized: ApiErr<HttpError>(
  ///     statusCode: 401,
  ///     errorType: HttpError.unauthorized,
  ///     message: HttpMessage(title: 'Unauthorized', details: 'Authentication required.'),
  ///   ),
  /// });
  /// ```
  static void registerAllExceptionTypes<T>(Map<T, ApiErr> exceptionTypeMap) {
    _errorRegistry.addAll(exceptionTypeMap);
  }

  /// Registers an error template associated with a combination of exception type, status codes, and error types.
  ///
  /// This method allows defining specific error handling based on the context:
  /// the *type* of the original exception (e.g., `DioException`), potential HTTP *status codes*,
  /// and potential categorized *error types*. The template ([error]) will be returned by
  /// [fromStatusAndType] if the provided context matches *any* of the specified status codes
  /// OR *any* of the error types, AND the exception type matches.
  ///
  /// Parameters:
  ///   * [exceptionType] - The runtime type of the exception this mapping applies to (e.g., `DioException`, `SocketException`).
  ///   * [statusCodes] - List of HTTP status codes that trigger this mapping for the given exception type.
  ///   * [errorTypes] - List of categorized error types ([E]) that trigger this mapping for the given exception type.
  ///   * [error] - The [ApiErr] template to use when a match is found.
  ///
  /// Example:
  /// ```dart
  /// // Assuming AuthError extends HttpError or is a separate enum E
  /// ApiErr.registerStatusTypeErrors<AuthError>(
  ///   DioException, // Applies only when the caught exception is DioException
  ///   [401, 403],    // Matches if status is 401 OR 403
  ///   [AuthError.tokenExpired, AuthError.permissionDenied], // OR if errorType is one of these
  ///   ApiErr<AuthError>( // The template to return
  ///     errorType: AuthError.permissionDenied, // Default type for the template
  ///     message: HttpMessage(
  ///       title: "Access Denied",
  ///       details: "You don't have permission or your session expired."
  ///     )
  ///     // statusCode will be overridden by fromStatusAndType if needed based on template/actual code
  ///   )
  /// );
  /// ```
  static void registerStatusTypeErrors<E>(
      Type exceptionType, // Use Type for clarity
      List<int> statusCodes,
      List<E> errorTypes,
      ApiErr<E> error
      ) {
    _errorRegistry[_StatusTypeKey<E>(
      exceptionType: exceptionType,
      statusCodes: statusCodes,
      errorTypes: errorTypes,
    )] = error;
  }

  /// Registers multiple error mappings for combinations of exception types, status codes, and error types.
  ///
  /// This is a batch version of [registerStatusTypeErrors]. The map key is a tuple containing:
  ///   1. The exception type (`Type`).
  ///   2. A list of status codes (`List<int>`).
  ///   3. A list of error types (`List<E>`).
  /// The map value is the `ApiErr<E>` template.
  ///
  /// Example:
  /// ```dart
  /// // Assuming DioException and SocketException exist
  /// // Assuming HttpError and NetworkError are enums used for E
  ///
  /// // Define templates first for clarity
  /// final authErrorTemplate = ApiErr<HttpError>(errorType: HttpError.unauthorized, message: HttpMessage(title: 'Auth Error', details: 'Please login.'));
  /// final validationErrorTemplate = ApiErr<HttpError>(errorType: HttpError.badRequest, message: HttpMessage(title: 'Invalid Data', details: 'Check input fields.'));
  /// final networkErrorTemplate = ApiErr<NetworkError>(errorType: NetworkError.noConnection, message: HttpMessage(title: 'Network Issue', details: 'Cannot connect.'));
  ///
  /// ApiErr.registerAllStatusTypeErrors<HttpError>({
  ///   (DioException, [401, 403], [HttpError.unauthorized]): authErrorTemplate,
  ///   (DioException, [400, 422], [HttpError.badRequest, HttpError.validationFailed]): validationErrorTemplate,
  /// });
  ///
  /// ApiErr.registerAllStatusTypeErrors<NetworkError>({
  ///   (SocketException, [], [NetworkError.noConnection, NetworkError.hostUnreachable]): networkErrorTemplate,
  ///   (TimeoutException, [408], [NetworkError.timeout]): ApiErr<NetworkError>(...), // Another template example
  /// });
  /// ```
  static void registerAllStatusTypeErrors<E>(Map<(Type, List<int>, List<E>), ApiErr<E>> statusTypeMap) {
    statusTypeMap.forEach((key, value) {
      _errorRegistry[_StatusTypeKey<E>(
        exceptionType: key.$1, // Item1: Exception Type
        statusCodes: key.$2,   // Item2: Status Codes List
        errorTypes: key.$3,    // Item3: Error Types List
      )] = value;
    });
  }

  // --- Central Setup Method ---

  /// Sets up error handling mappings centrally, typically at application startup.
  ///
  /// Allows registering both simple error type mappings and complex status/type/exception mappings.
  ///
  /// Parameters:
  ///   * [exceptionTypeMap] - A map for registering simple error type templates (calls [registerAllExceptionTypes]).
  ///   * [statusTypeMap] - A map for registering complex contextual error templates (calls [registerAllStatusTypeErrors]).
  ///
  /// Example:
  /// ```dart
  /// // Define templates
  /// final badRequestTemplate = ApiErr<HttpError>(...);
  /// final notFoundTemplate = ApiErr<HttpError>(...);
  /// final serverErrorTemplate = ApiErr<HttpError>(...);
  /// final dioAuthTemplate = ApiErr<HttpError>(...);
  /// final dioTimeoutTemplate = ApiErr<NetworkError>(...);
  ///
  /// ApiErr.setupErrorHandling<HttpError, NetworkError>( // Specify types if maps use different E
  ///   exceptionTypeMap: { // Simple type mappings
  ///     HttpError.badRequest: badRequestTemplate,
  ///     HttpError.notFound: notFoundTemplate,
  ///     HttpError.internalServerError: serverErrorTemplate,
  ///     // Can add NetworkError types here too if HttpError and NetworkError are compatible
  ///   },
  ///   statusTypeMap: { // Complex contextual mappings
  ///     // Using HttpError as E
  ///     (DioException, [401, 403], [HttpError.unauthorized]): dioAuthTemplate,
  ///     // Using NetworkError as E
  ///     (DioException, [408], [NetworkError.timeout]): dioTimeoutTemplate,
  ///   },
  /// );
  /// ```
  static void setupErrorHandling<E1, E2>({ // Allow different types E for each map if needed
    Map<dynamic, ApiErr<E1>>? exceptionTypeMap,
    Map<(Type, List<int>, List<dynamic>), ApiErr<E2>>? statusTypeMap, // Use dynamic for List<E> here
  }) {
    if (exceptionTypeMap != null) {
      registerAllExceptionTypes<dynamic>(exceptionTypeMap); // Register with dynamic type T
    }
    if (statusTypeMap != null) {
      // Cast needed because the method expects specific E, but setup handles potentially mixed types.
      // This assumes the caller provides maps with compatible ApiErr<E> types.
      registerAllStatusTypeErrors<dynamic>(statusTypeMap.map(
              (key, value) => MapEntry(key, value as ApiErr<dynamic>)
      ));
    }
  }

  // --- Static Factory Methods ---

  /// Creates an [ApiErr] based on a registered error type mapping.
  ///
  /// Looks up the [exceptionType] in the registry. If no direct mapping exists,
  /// returns a generic [ApiErr]. Useful for creating errors based purely on category.
  ///
  /// Example:
  /// ```dart
  /// // Assuming HttpError.notFound was registered via registerExceptionType
  /// final error = ApiErr.fromExceptionType(HttpError.notFound);
  /// print(error); // Output based on the registered template for notFound
  ///
  /// final unknownError = ApiErr.fromExceptionType(GenericErrorType.unknown); // If not registered
  /// print(unknownError); // Output: "Error: An unexpected error occurred"
  /// ```
  static ApiErr<T> fromExceptionType<T>(T exceptionType) {
    final registeredError = _errorRegistry[exceptionType];
    if (registeredError != null && registeredError is ApiErr<T>) {
      return registeredError;
    } else {
      // Fallback if no template is registered for this type
      return ApiErr<T>(
        // exception: exceptionType, // Avoid putting the type itself as the exception object
          errorType: exceptionType, // Keep the type for categorization
          message: HttpMessage(
              title: 'Error',
              details: 'An unexpected error occurred for type $exceptionType'
          )
      );
    }
  }


  /// Creates an [ApiErr] based on context: HTTP status code, error type, and optionally the original exception.
  ///
  /// This is the primary factory for handling errors derived from API responses.
  /// It prioritizes matches based on context:
  /// 1. Checks for mappings registered via [registerStatusTypeErrors] that match the
  ///    `exception.runtimeType`, `statusCode`, OR `errorType`.
  /// 2. If no context-specific match is found, it falls back to finding a template
  ///    registered via [registerExceptionType] based solely on the `errorType`.
  /// 3. If neither finds a template, it returns a generic [ApiErr].
  ///
  /// When a template is found (especially via fallback), it typically creates a *new*
  /// [ApiErr] instance using the template's message/validations but updating the
  /// `statusCode`, `errorType`, and `exception` to reflect the actual error context.
  ///
  /// Parameters:
  ///   * [statusCode] - The HTTP status code from the response.
  ///   * [errorType] - The categorized error type (e.g., from an enum).
  ///   * [exception] - Optional: The original exception object caught (e.g., `DioException`).
  ///
  /// Example:
  /// ```dart
  /// // Assuming registrations exist for DioException + 401 -> auth error
  /// // and HttpError.badRequest -> validation error
  /// try {
  ///   // Make API call using Dio
  /// } on DioException catch (e) {
  ///   if (e.response != null) {
  ///     final statusCode = e.response!.statusCode!;
  ///     // Assume determineErrorType maps status codes/response data to your enum E (e.g., HttpError)
  ///     final errorType = determineErrorType(e.response!);
  ///     final apiError = ApiErr.fromStatusAndType<HttpError>(statusCode, errorType, e);
  ///     // apiError will be based on the registered templates
  ///     handleError(apiError);
  ///   } else {
  ///     // Network error, maybe map DioExceptionType to a NetworkError enum
  ///     final networkErrorType = mapDioExceptionType(e.type);
  ///     final apiError = ApiErr.fromStatusAndType<NetworkError>(0, networkErrorType, e); // Use 0 or specific code for network errors
  ///     handleError(apiError);
  ///   }
  /// }
  /// ```
  static ApiErr<E> fromStatusAndType<E>(int statusCode, E errorType, [Object? exception]) {
    ApiErr<E>? matchedTemplate; // Variable to store the best matching template found

    // 1. Iterate ONCE through the registry looking for the best match
    for (var entry in _errorRegistry.entries) {
      if (entry.key is _StatusTypeKey<E>) {
        final key = entry.key as _StatusTypeKey<E>;

        // 2. Priority 1: Match with specific Exception Type context
        if (exception != null && key.matches(statusCode, errorType, exception)) {
          // Most specific match found based on exception type + status/type.
          matchedTemplate = entry.value as ApiErr<E>;
          break; // Exit loop, best match found.
        }

        // 3. Priority 2: Match without specific Exception Type context (if Priority 1 not met yet)
        // This check might be less useful if 'matches' already requires exceptionType match.
        // Consider if _StatusTypeKey needs separate logic or if this check is redundant.
        // Keeping it for now based on previous structure, assuming _StatusTypeKey might evolve.
        if (matchedTemplate == null && key.matchesWithoutException(statusCode, errorType)) {
          // Found a potential match based on status/type for the registered exception type.
          // Store it but continue searching for a potential Priority 1 match later in the loop.
          matchedTemplate = entry.value as ApiErr<E>;
          // DO NOT break here.
        }
      }
    }

    // 4. If a context-specific template was found via _StatusTypeKey
    if (matchedTemplate != null) {
      // Return a new instance based on the template, but with actual context.
      // This ensures the returned error reflects the *actual* status code and exception.
      return ApiErr<E>(
        statusCode: statusCode, // Use actual status code
        errorType: errorType,   // Use actual error type
        exception: exception ?? matchedTemplate.exception, // Use actual exception
        message: matchedTemplate.message, // Use template message
        validations: matchedTemplate.validations, // Use template validations
        // stackTrace: stackTrace, // Optionally add current stackTrace if needed
      );
    }

    // 5. Fallback 1: Look for a simple template based only on Error Type
    final typeErrorTemplate = _errorRegistry[errorType];
    if (typeErrorTemplate != null && typeErrorTemplate is ApiErr<E>) {
      // Found a simple template by type. Create a specific instance.
      return ApiErr<E>(
        statusCode: statusCode, // Use actual status code
        errorType: errorType,   // Use actual error type
        message: typeErrorTemplate.message, // Template message
        validations: typeErrorTemplate.validations, // Template validations
        exception: exception ?? typeErrorTemplate.exception, // Include actual exception if available
        // stackTrace: stackTrace, // Optionally add current stackTrace
      );
    }

    // 6. Fallback Final: Create a generic error if no template was found
    return ApiErr<E>(
      statusCode: statusCode,
      errorType: errorType,
      exception: exception, // Include the original exception
      message: HttpMessage(
        title: 'Error $statusCode',
        details: exception?.toString() ?? 'An unspecified error occurred.',
      ),
      // stackTrace: stackTrace, // Optionally add current stackTrace
    );
  }
}

// --- Helper Key Class (Private) ---

/// Private class used as a complex key in the `_errorRegistry`.
///
/// Enables mapping errors based on a combination of the original exception's *type*,
/// a list of potential HTTP *status codes*, and a list of potential categorized *error types*.
///
/// Type parameter [E] is the type of the categorized error types (e.g., an enum).
class _StatusTypeKey<E> {
  /// The runtime type of the Exception this key targets (e.g., `DioException`, `SocketException`).
  final Type exceptionType;

  /// List of HTTP status codes associated with this key. Sorted for consistent hashing/equality.
  final List<int> statusCodes;

  /// List of categorized error types (of type [E]) associated with this key.
  final List<E> errorTypes;

  /// Creates a new key for the error template registry.
  ///
  /// Parameters:
  ///   * [exceptionType] - The `Type` of the exception to match (e.g., `DioException`).
  ///   * [statusCodes] - List of HTTP status codes relevant to this key.
  ///   * [errorTypes] - List of categorized error types ([E]) relevant to this key.
  _StatusTypeKey({
    required this.exceptionType,
    required this.statusCodes,
    required this.errorTypes,
  }) {
    // Sort status codes for consistent hashCode and equality checks
    statusCodes.sort();
    // Consider sorting errorTypes if they are comparable and order doesn't matter.
  }

  // Cache for hashCode calculation
  int? _hashCode;

  /// Checks if this key's criteria match the provided context.
  ///
  /// A match occurs if:
  /// 1. The provided `exception`'s runtime type matches this key's `exceptionType`.
  /// 2. AND (The provided `status` is contained within this key's `statusCodes` OR
  ///         the provided `type` is contained within this key's `errorTypes`).
  ///
  /// This logic allows registering a template that handles multiple status codes or error types
  /// for a specific exception type.
  bool matches(int status, E type, Object exception) {
    // Check if the runtime type of the passed exception matches the type stored in the key
    final exceptionTypeMatch = exception.runtimeType == exceptionType;

    if (!exceptionTypeMatch) {
      return false;
    }

    // Check if either the status code OR the error type matches the lists in the key
    final statusMatch = statusCodes.contains(status);
    final typeMatch = errorTypes.contains(type);

    return statusMatch || typeMatch;
  }

  /// Checks if this key matches based on status code or error type, *without* considering the exception instance.
  ///
  /// A match occurs if the provided `status` is in `statusCodes` OR the `type` is in `errorTypes`.
  /// NOTE: The usefulness of this specific method depends on the desired lookup logic in `fromStatusAndType`.
  /// If `fromStatusAndType` *always* requires an exception type match for `_StatusTypeKey`,
  /// this method might be less relevant or could be merged into `matches`.
  bool matchesWithoutException(int status, E type) {
    final statusMatch = statusCodes.contains(status);
    final typeMatch = errorTypes.contains(type);
    return statusMatch || typeMatch;
  }


  /// Equality operator.
  ///
  /// IMPORTANT: This implementation considers two keys equal if they target the
  /// *same exception type* AND there is *any overlap* in their status codes AND
  /// *any overlap* in their error types. This is complex and means multiple distinct
  /// registrations might be considered "equal" if they share elements.
  /// This usually isn't standard behavior for map keys. Ensure this is the intended logic.
  /// A more standard approach would require exact list equality.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _StatusTypeKey<E>) return false; // Check generic type E as well

    // Check for same exception type
    if (exceptionType != other.exceptionType) return false;

    // Check for *any* overlap in status codes (complex equality)
    final statusOverlap = statusCodes.any((s) => other.statusCodes.contains(s));
    if (!statusOverlap) return false;

    // Check for *any* overlap in error types (complex equality)
    final typeOverlap = errorTypes.any((t) => other.errorTypes.contains(t));
    return typeOverlap;

    // // --- Alternative: Standard Equality (Requires exact lists) ---
    // if (exceptionType != other.exceptionType) return false;
    // if (const ListEquality().equals(statusCodes, other.statusCodes) &&
    //     const ListEquality().equals(errorTypes, other.errorTypes)) {
    //   return true;
    // }
    // return false;
  }

  @override
  int get hashCode {
    // Hash code calculation should be consistent with the `==` operator logic.
    // Hashing based on list content AND exception type.
    if (_hashCode != null) return _hashCode!;

    // Combine hash codes of the components. Use list hash codes.
    _hashCode = Object.hash(
        exceptionType,
        Object.hashAll(statusCodes), // Hash based on list content
        Object.hashAll(errorTypes)   // Hash based on list content
    );
    // Note: The complex overlap-based equality makes consistent hashing difficult.
    // The standard Object.hashAll used here assumes value equality of the lists.

    return _hashCode!;
  }


  @override
  String toString() {
    return '_StatusTypeKey<${E.toString()}>(exceptionType: $exceptionType, statusCodes: $statusCodes, errorTypes: $errorTypes)';
  }
}