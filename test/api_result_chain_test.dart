import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

// Mock class for testing
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'].toString(), name: json['name'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class Post {
  final String id;
  final String userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ title.hashCode ^ body.hashCode;
}

class Comment {
  final String id;
  final String postId;
  final String name;
  final String email;
  final String body;

  Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      postId: json['postId'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.postId == postId &&
        other.name == name &&
        other.email == email &&
        other.body == body;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      postId.hashCode ^
      name.hashCode ^
      email.hashCode ^
      body.hashCode;
}

void main() {
  group('ApiResult complex chains', () {
    test('Chains multiple map operations successfully', () {
      // Start with a successful user result
      final userResult = ApiResult<User>.ok(User(id: '1', name: 'John Doe'));

      // Chain multiple map operations
      final result = userResult
          .map((user) => user.name)
          .map((name) => name.toUpperCase())
          .map((upper) => upper.split(' '))
          .map((parts) => '${parts[1]}, ${parts[0]}');

      expect(result.isOk, isTrue);
      expect(result.data, equals('DOE, JOHN'));
    });

    test('Chain breaks at first error', () {
      // Create an error result
      final errorResult = ApiResult<User>.err(
        ApiErr(
          statusCode: 404,
          message: HttpMessage(
            success: false,
            title: 'Not Found',
            details: 'User not found',
          ),
        ),
      );

      // Chain multiple map operations
      final result = errorResult
          .map((user) => user.name)
          .map((name) => name.toUpperCase())
          .map((upper) => upper.split(' '))
          .map((parts) => '${parts[1]}, ${parts[0]}');

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.statusCode, equals(404));
      expect(result.errorOrNull?.message?.details, equals('User not found'));
    });

    test('Error transformation in chain', () {
      // Create an error result
      final errorResult = ApiResult<User>.err(
        ApiErr(
          statusCode: 404,
          message: HttpMessage(
            success: false,
            title: 'Not Found',
            details: 'User not found',
          ),
        ),
      );

      // Chain with error transformation
      final result = errorResult.map(
        (user) => user.name,
        (error) => ApiErr(
          statusCode: 500,
          message: HttpMessage(
            success: false,
            title: 'Transformed Error',
            details: 'Original error: ${error.message?.details}',
          ),
        ),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.statusCode, equals(500));
      expect(result.errorOrNull?.message?.title, equals('Transformed Error'));
      expect(result.errorOrNull?.message?.details, contains('User not found'));
    });

    test('Multiple error transformations in chain', () {
      // Create an error result
      final errorResult = ApiResult<User>.err(
        ApiErr(
          statusCode: 404,
          message: HttpMessage(
            success: false,
            title: 'Not Found',
            details: 'User not found',
          ),
        ),
      );

      // Chain with multiple error transformations
      final result = errorResult
          .map(
            (user) => user.name,
            (error) => ApiErr(
              statusCode: 400,
              message: HttpMessage(
                success: false,
                title: 'First Transform',
                details: 'Step 1: ${error.message?.details}',
              ),
            ),
          )
          .map(
            (name) => name.toUpperCase(),
            (error) => ApiErr(
              statusCode: 500,
              message: HttpMessage(
                success: false,
                title: 'Second Transform',
                details: 'Step 2: ${error.message?.details}',
              ),
            ),
          );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.statusCode, equals(500));
      expect(result.errorOrNull?.message?.title, equals('Second Transform'));
      expect(
        result.errorOrNull?.message?.details,
        contains('Step 2: Step 1: User not found'),
      );
    });
  });

  group('ApiResult complex flatMap operations', () {
    test('Chains multiple flatMap operations successfully', () {
      // Mock repository functions
      ApiResult<User> getUser(String id) {
        return ApiResult.ok(User(id: id, name: 'John Doe'));
      }

      ApiResult<List<Post>> getUserPosts(User user) {
        return ApiResult.ok([
          Post(id: '1', userId: user.id, title: 'Post 1', body: 'Content 1'),
          Post(id: '2', userId: user.id, title: 'Post 2', body: 'Content 2'),
        ]);
      }

      ApiResult<List<Comment>> getPostComments(Post post) {
        return ApiResult.ok([
          Comment(
            id: '1',
            postId: post.id,
            name: 'Comment 1',
            email: 'user1@example.com',
            body: 'Great post!',
          ),
          Comment(
            id: '2',
            postId: post.id,
            name: 'Comment 2',
            email: 'user2@example.com',
            body: 'Interesting',
          ),
        ]);
      }

      // Chain operations
      final result = getUser('1').flatMap((user) {
        return getUserPosts(user).flatMap((posts) {
          final firstPost = posts.first;
          return getPostComments(firstPost).map((comments) {
            return {'user': user, 'post': firstPost, 'comments': comments};
          });
        });
      });

      expect(result.isOk, isTrue);
      expect(result.data['user'], isA<User>());
      expect(result.data['post'], isA<Post>());
      expect(result.data['comments'], isA<List<Comment>>());
      expect((result.data['comments'] as List<Comment>).length, equals(2));
    });

    test('Chain breaks at first error and preserves error context', () {
      // Mock repository functions with error
      ApiResult<User> getUser(String id) {
        return ApiResult.ok(User(id: id, name: 'John Doe'));
      }

      ApiResult<List<Post>> getUserPosts(User user) {
        return ApiResult.err(
          ApiErr(
            statusCode: 500,
            message: HttpMessage(
              success: false,
              title: 'Server Error',
              details: 'Failed to fetch posts for user ${user.id}',
            ),
          ),
        );
      }

      ApiResult<List<Comment>> getPostComments(Post post) {
        return ApiResult.ok([
          Comment(
            id: '1',
            postId: post.id,
            name: 'Comment 1',
            email: 'user1@example.com',
            body: 'Great post!',
          ),
        ]);
      }

      // Chain operations
      final result = getUser('1').flatMap((user) {
        return getUserPosts(user).flatMap((posts) {
          final firstPost = posts.first;
          return getPostComments(firstPost).map((comments) {
            return {'user': user, 'post': firstPost, 'comments': comments};
          });
        });
      });

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.statusCode, equals(500));
      expect(
        result.errorOrNull?.message?.details,
        contains('Failed to fetch posts for user 1'),
      );
    });

    test('Error recovery in the middle of a chain', () {
      // Mock repository functions with error and recovery
      ApiResult<User> getUser(String id) {
        return ApiResult.ok(User(id: id, name: 'John Doe'));
      }

      ApiResult<List<Post>> getUserPosts(User user) {
        return ApiResult.err(
          ApiErr(
            statusCode: 500,
            message: HttpMessage(
              success: false,
              title: 'Server Error',
              details: 'Failed to fetch posts for user ${user.id}',
            ),
          ),
        );
      }

      ApiResult<List<Post>> getFallbackPosts(User user) {
        return ApiResult.ok([
          Post(
            id: '999',
            userId: user.id,
            title: 'Fallback Post',
            body: 'Fallback Content',
          ),
        ]);
      }

      // Chain operations with recovery
      final result = getUser('1').flatMap((user) {
        return getUserPosts(user)
            .recover((error) {
              if (error.statusCode == 500) {
                // Recovery logic
                return getFallbackPosts(user);
              }
              return ApiResult.err(error); // Propagate other errors
            })
            .flatMap((posts) {
              return ApiResult.ok({
                'user': user,
                'posts': posts,
                'postsCount': posts.length,
              });
            });
      });

      expect(result.isOk, isTrue);
      expect(result.data['user'], isA<User>());
      expect(
        (result.data['posts'] as List<Post>).first.title,
        equals('Fallback Post'),
      );
      expect(result.data['postsCount'], equals(1));
    });

    test('Complex nested error transformations', () {
      // Mock repository functions with nested error handling
      ApiResult<User> getUser(String id) {
        if (id == '404') {
          return ApiResult.err(
            ApiErr(
              statusCode: 404,
              message: HttpMessage(
                success: false,
                title: 'Not Found',
                details: 'User not found',
              ),
            ),
          );
        }
        return ApiResult.ok(User(id: id, name: 'John Doe'));
      }

      // Chain with complex error handling
      final result = getUser(
        '404',
      ).flatMap((user) => ApiResult.ok('User: ${user.name}'), (error) {
        if (error.statusCode == 404) {
          return ApiResult.err(
            ApiErr(
              statusCode: 404,
              message: HttpMessage(
                success: false,
                title: 'Custom Not Found',
                details:
                    'Could not find the requested user. Please try another ID.',
              ),
            ),
          );
        } else if (error.statusCode == 401) {
          return ApiResult.err(
            ApiErr(
              statusCode: 401,
              message: HttpMessage(
                success: false,
                title: 'Authentication Required',
                details: 'Please login to access this resource.',
              ),
            ),
          );
        } else {
          return ApiResult.err(
            ApiErr(
              statusCode: 500,
              message: HttpMessage(
                success: false,
                title: 'System Error',
                details:
                    'An unexpected error occurred. Original error: ${error.message?.details}',
              ),
            ),
          );
        }
      });

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.statusCode, equals(404));
      expect(result.errorOrNull?.message?.title, equals('Custom Not Found'));
      expect(
        result.errorOrNull?.message?.details,
        contains('Could not find the requested user'),
      );
    });

    test('Deep nested flatMap chain with type transformations', () {
      // Start with a successful result
      final initialResult = ApiResult<String>.ok('123');

      // Chain of operations with type changes
      final result = initialResult
          .flatMap((userId) {
            // Convert string to User
            final user = User(id: userId, name: 'User $userId');
            return ApiResult<User>.ok(user);
          })
          .flatMap((user) {
            // Convert User to List<Post>
            final posts = [
              Post(
                id: '1',
                userId: user.id,
                title: 'Post 1',
                body: 'Content 1',
              ),
              Post(
                id: '2',
                userId: user.id,
                title: 'Post 2',
                body: 'Content 2',
              ),
            ];
            return ApiResult<List<Post>>.ok(posts);
          })
          .flatMap((posts) {
            // Convert List<Post> to Post count
            return ApiResult<int>.ok(posts.length);
          })
          .flatMap((postCount) {
            // Convert post count to message
            return ApiResult<Map<String, dynamic>>.ok({
              'message': 'Found $postCount posts',
              'count': postCount,
            });
          });

      expect(result.isOk, isTrue);
      expect(result.data['message'], equals('Found 2 posts'));
      expect(result.data['count'], equals(2));
    });
  });

  group('ApiResult error handling and transformation', () {
    test('Multiple error handling strategies in chain', () {
      // Define error handling functions
      ApiErr handleNetworkError(ApiErr error) {
        return ApiErr(
          statusCode: error.statusCode,
          message: HttpMessage(
            success: false,
            title: 'Network Error',
            details: 'Please check your connection and try again',
          ),
        );
      }

      ApiErr handleAuthError(ApiErr error) {
        return ApiErr(
          statusCode: error.statusCode,
          message: HttpMessage(
            success: false,
            title: 'Authentication Error',
            details: 'Please login to continue',
          ),
        );
      }

      ApiErr handleServerError(ApiErr error) {
        return ApiErr(
          statusCode: error.statusCode,
          message: HttpMessage(
            success: false,
            title: 'Server Error',
            details: 'Our servers are experiencing issues',
          ),
        );
      }

      // Create different error scenarios
      final networkError = ApiResult<User>.err(
        ApiErr(
          statusCode: 0,
          exception: Exception('Network connection failed'),
        ),
      );

      final authError = ApiResult<User>.err(
        ApiErr(
          statusCode: 401,
          message: HttpMessage(
            success: false,
            title: 'Unauthorized',
            details: 'Token expired',
          ),
        ),
      );

      final serverError = ApiResult<User>.err(
        ApiErr(
          statusCode: 500,
          message: HttpMessage(
            success: false,
            title: 'Internal Error',
            details: 'Database failure',
          ),
        ),
      );

      // Apply different error handlers based on status code
      processError(ApiErr error) {
        if (error.statusCode == 0) {
          return handleNetworkError(error);
        } else if (error.statusCode == 401 || error.statusCode == 403) {
          return handleAuthError(error);
        } else if (error.statusCode! >= 500) {
          return handleServerError(error);
        }
        return error;
      }

      // Process each error
      final processedNetworkError = networkError.map(
        (user) => user,
        processError,
      );
      final processedAuthError = authError.map((user) => user, processError);
      final processedServerError = serverError.map(
        (user) => user,
        processError,
      );

      // Check results
      expect(
        processedNetworkError.errorOrNull?.message?.title,
        equals('Network Error'),
      );
      expect(
        processedAuthError.errorOrNull?.message?.title,
        equals('Authentication Error'),
      );
      expect(
        processedServerError.errorOrNull?.message?.title,
        equals('Server Error'),
      );
    });

    test('Error transformation in nested operations', () {
      // Create a chain of operations with nested errors
      final result = ApiResult<String>.ok('start')
          .flatMap((value) {
            // First flatMap returns an error
            return ApiResult<int>.err(
              ApiErr(
                statusCode: 400,
                message: HttpMessage(
                  success: false,
                  title: 'Level 1 Error',
                  details: 'Error at first level',
                ),
              ),
            );
          })
          .flatMap(
            (value) {
              // This would transform the success value
              return ApiResult<bool>.ok(value > 0);
            },
            (error) {
              // This transforms the Level 1 error
              return ApiResult<bool>.err(
                ApiErr(
                  statusCode: error.statusCode,
                  message: HttpMessage(
                    success: false,
                    title: 'Transformed Level 1',
                    details: 'Transformed: ${error.message?.details}',
                  ),
                ),
              );
            },
          )
          .flatMap(
            (value) {
              // This would transform the success value again
              return ApiResult<String>.ok(value ? 'Yes' : 'No');
            },
            (error) {
              // This transforms the Level 2 error
              return ApiResult<String>.err(
                ApiErr(
                  statusCode: error.statusCode,
                  message: HttpMessage(
                    success: false,
                    title: 'Final Error',
                    details: 'Final: ${error.message?.details}',
                  ),
                ),
              );
            },
          );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.message?.title, equals('Final Error'));
      expect(
        result.errorOrNull?.message?.details,
        contains('Final: Transformed: Error at first level'),
      );
    });

    test('Error recovery with fallback value in complex chain', () {
      // Define a chain of operations where an error occurs in the middle
      final initialValue = ApiResult<int>.ok(10);

      final result = initialValue
          .flatMap((value) {
            if (value > 5) {
              // Produce an error in the middle of the chain
              return ApiResult<String>.err(
                ApiErr(
                  statusCode: 400,
                  message: HttpMessage(
                    success: false,
                    title: 'Value Too Large',
                    details: 'Value $value exceeds maximum of 5',
                  ),
                ),
              );
            }
            return ApiResult<String>.ok('Value is $value');
          })
          .recover((error) {
            // Recover from the error with a fallback value
            return ApiResult<String>.ok(
              'Fallback: Error was ${error.message?.details}',
            );
          })
          .flatMap((value) {
            // Continue the chain with the recovered value
            return ApiResult<Map<String, dynamic>>.ok({
              'originalOrFallback': value,
              'processed': true,
            });
          });

      expect(result.isOk, isTrue);
      expect(result.data['originalOrFallback'], contains('Fallback'));
      expect(
        result.data['originalOrFallback'],
        contains('Value 10 exceeds maximum of 5'),
      );
      expect(result.data['processed'], isTrue);
    });
  });

  group('ApiResult unexpected data handling', () {
    test('Handles unexpected response structures gracefully', () {
      // Mock an unexpected API response format
      final unexpectedResponse = ApiResponse.success({
        'meta': {'status': 'success'},
        'data': null, // Missing expected data
      });

      // Try to convert to a User
      final result = ApiResult.from<User>(
        response: unexpectedResponse,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isErr, isTrue);
      expect(
        result.errorOrNull?.message?.title,
        equals('Data Processing Error'),
      );
    });

    test('Handles API schema changes gracefully', () {
      // Mock a response with changed schema (field name changes)
      final changedSchemaResponse = ApiResponse.success({
        'userId': '123', // Changed from 'id'
        'userName': 'John Doe', // Changed from 'name'
      });

      // Try to convert with schema handling
      final result = ApiResult.from<User>(
        response: changedSchemaResponse,
        onData: (data) {
          try {
            // Try the new schema first
            if (data.containsKey('userId') && data.containsKey('userName')) {
              return User(
                id: data['userId'].toString(),
                name: data['userName'] as String,
              );
            }
            // Fall back to the old schema
            return User.fromJson(data);
          } catch (e) {
            throw FormatException('Invalid user format: $e');
          }
        },
      );

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('John Doe'));
    });

    test('Handles missing required fields gracefully', () {
      // Mock a response with missing required fields
      final missingFieldsResponse = ApiResponse.success({
        'id': '123',
        // Missing 'name' field
      });

      // Try to convert with error handling for missing fields
      final result = ApiResult.from<User>(
        response: missingFieldsResponse,
        onData: (data) {
          if (!data.containsKey('name')) {
            throw FormatException('Missing required field: name');
          }
          return User.fromJson(data);
        },
      );

      expect(result.isErr, isTrue);
      expect(
        result.errorOrNull?.message?.title,
        equals('Data Processing Error'),
      );
      expect(
        result.errorOrNull?.message?.details,
        contains('Missing required field: name'),
      );
    });

    test('Handles unexpected data types gracefully', () {
      // Mock a response with unexpected data types
      final wrongTypesResponse = ApiResponse.success({
        'id': 123, // Number instead of string
        'name': true, // Boolean instead of string
      });

      // Try to convert with type coercion
      final result = ApiResult.from<User>(
        response: wrongTypesResponse,
        onData: (data) {
          return User(
            id: data['id'].toString(), // Convert to string
            name: data['name'].toString(), // Convert to string
          );
        },
      );

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('true'));
    });
  });
}
