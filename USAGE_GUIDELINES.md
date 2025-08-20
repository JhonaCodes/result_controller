# Result Controller Usage Guidelines

## 🚨 Lint Rules and Best Practices

Este documento describe las reglas de lint y mejores prácticas para usar Result Controller correctamente.

## ✅ Uso Correcto

### 1. Siempre usa Ok() y Err()
```dart
// ✅ CORRECTO
Result<String, String> getUserName() {
  return Ok('John Doe');
}

Result<String, String> getError() {
  return Err('User not found');
}

// ❌ INCORRECTO - Nunca retornes null
Result<String, String> badExample() {
  return null; // ❌ Lint error: avoid_returning_null
}
```

### 2. Usa const constructors cuando sea posible
```dart
// ✅ CORRECTO
const result = Ok('constant value');
const error = Err('constant error');

// ❌ EVITAR
final result = Ok('constant value'); // Lint: prefer_const_constructors
```

### 3. Prefiere variables finales
```dart
// ✅ CORRECTO
final Result<String, String> result = getUserData();

// ❌ EVITAR
Result<String, String> result = getUserData(); // Lint: prefer_final_locals
```

### 4. Manejo de errores con when()
```dart
// ✅ CORRECTO
result.when(
  ok: (data) => print('Success: $data'),
  err: (error) => print('Error: $error'),
);

// ❌ EVITAR - No accedas directamente a .data sin verificar
final value = result.data; // Puede lanzar excepción
```

### 5. Operaciones asíncronas
```dart
// ✅ CORRECTO
Future<Result<User, ApiErr>> fetchUser() async {
  return await Result.tryAsync(() async {
    final response = await http.get('/user');
    return User.fromJson(response.data);
  });
}

// ❌ INCORRECTO - No retornes null en futures
Future<Result<User, ApiErr>?> badFetchUser() async {
  return null; // ❌ Lint error: avoid_returning_null_for_future
}
```

## 🎯 Patrones Recomendados

### Chaining con flatMap
```dart
final result = await getUserId()
  .flatMap((id) => fetchUserProfile(id))
  .flatMap((profile) => updateUserStatus(profile));

result.when(
  ok: (updatedProfile) => showSuccess(updatedProfile),
  err: (error) => showError(error),
);
```

### Error Recovery
```dart
final result = await fetchFromNetwork()
  .recover((error) => fetchFromCache())
  .recover((error) => Ok(getDefaultData()));
```

### Transformación de tipos
```dart
final stringResult = numberResult.map((num) => num.toString());
final userResult = jsonResult.map((json) => User.fromJson(json));
```

## 🚫 Anti-Patrones a Evitar

### 1. No uses try-catch tradicional
```dart
// ❌ EVITAR
try {
  final data = dangerousOperation();
  return Ok(data);
} catch (e) {
  return Err(e.toString());
}

// ✅ USAR Result.trySync
return Result.trySync(() => dangerousOperation());
```

### 2. No ignores errores
```dart
// ❌ EVITAR
result.when(
  ok: (data) => processData(data),
  err: (error) => {}, // ❌ Error vacío
);

// ✅ CORRECTO
result.when(
  ok: (data) => processData(data),
  err: (error) => logError(error),
);
```

### 3. No uses variables mutables innecesarias
```dart
// ❌ EVITAR
var result = Ok('initial'); // Lint: prefer_final_locals
result = Err('changed');

// ✅ CORRECTO
final initialResult = Ok('initial');
final changedResult = Err('changed');
```

## 📋 Checklist de Revisión

Antes de hacer commit, verifica:

- [ ] ✅ Todos los métodos que pueden fallar retornan `Result<T, E>`
- [ ] ✅ Usas `Ok()` y `Err()` en lugar de `null` o excepciones
- [ ] ✅ Variables declaradas como `final` cuando es posible
- [ ] ✅ Constructores `const` donde aplique
- [ ] ✅ Errores manejados con `when()` o métodos seguros
- [ ] ✅ Operaciones asíncronas usan `Result.tryAsync()`
- [ ] ✅ Documentación pública agregada a métodos públicos

## ⚙️ Configuración del Linter

Para aplicar estas reglas en tu proyecto, agrega a tu `analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  errors:
    avoid_returning_null: error
    avoid_returning_null_for_future: error
    
linter:
  rules:
    - prefer_const_constructors
    - prefer_final_locals
    - avoid_catching_errors
    - public_member_api_docs
```

## 🔧 IDE Configuration

### VS Code
Instala la extensión "Dart" que incluye soporte completo para estas reglas de lint.

### IntelliJ/Android Studio
Las reglas se aplican automáticamente con el plugin de Dart/Flutter.

---

**Nota**: Estas reglas están diseñadas para maximizar la seguridad de tipos y promover el uso correcto del patrón Result en tu código.