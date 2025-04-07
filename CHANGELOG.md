# Changelog

## [1.1.0]

### Breaking Changes
- Headers are now mandatory in `ok` and `err` constructors
- Removed default constructor that allowed optional headers
- Added status code validation (must be between 100 and 599)
- Improved exception logging system in `ApiErr`
- Added support for custom exception mapping
- Modified `whenList` behavior to handle mixed types
- Added `whenListType` method for better list typing
- Improved null value handling in lists
- Added `whenJsonListMap` method for processing dynamic JSON map lists
- Added extension methods for `Future<Result>`
- Improved async operation support
- Added error transformation utilities

### Added
- Better type handling in async operations
- Enhanced JSON processing support
- Better error handling in chained operations
- New data transformation utilities

### Fixed
- Null headers handling
- Status code validation
- Mixed list processing

## [1.0.3]
### Refactor
- `HttpError` to `HttpErr`

## [1.0.2]
### Refactor
- Cleaning extensions in result.
### Added
- More test cases.

## [1.0.1] 
### Documentation
- Update readme

## [1.0.0] - Initial Release

### Added
- Core `Result<T, E>` implementation
- `Ok` and `Err` classes for result handling
- `ApiResult` and `ApiResponse` for API-specific error management
- Comprehensive error handling methods
    - `when()`
    - `map()`
    - `flatMap()`
    - `mapError()`
    - `recover()`
- Async error handling methods
    - `trySync()`
    - `tryAsync()`
    - `trySyncMap()`
    - `tryAsyncMap()`
- Extension methods for collection operations
- JSON parsing utilities
- Detailed error reporting with `HttpMessage` and `ApiErr`

### Features
- Type-safe error handling
- Functional programming approach
- Flexible error transformation
- Support for both synchronous and asynchronous operations
- Comprehensive API response processing

## [0.1.0] - Pre-release Development

- Initial project structure
- Basic implementation of core components
- Extensive test coverage