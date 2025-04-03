# Changelog

## [1.0.1] 
## Readme
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