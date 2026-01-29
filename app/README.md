# WheelyTrails App

A Flutter application for trail enthusiasts, featuring a robust authentication system with secure persistence and seamless token management.

## Authentication Architecture

The application uses a **Token-Based Authentication** system (JWT + Refresh Token) integrated with **Riverpod** for state management and **Dio** for network requests.

### Core Components

The authentication layer is built upon the following key classes:

#### 1. `LoginScreen.dart` (UI Layer)
- **Role**: Handles user input and triggers the login process.
- **Integration**:
  - Uses `ref.read(authControllerProvider.notifier).login(email, password)` to initiate authentication.
  - Listen strictly to the action completion (`await`) to navigate to `/home` on success or show a `SnackBar` on failure.
  - Does *not* directly manage tokens; it delegates entirely to the controller.

#### 2. `auth_provider.dart` (State Management)
- **`AuthController`**: A `Notifier` that manages the `AuthState` (initial, authenticated, unauthenticated).
  - **Login**: Calls `AuthService`, updates state to `authenticated` with the user object, and persists the user to storage.
  - **Restore Session**: Called at startup (or via `authStartupProvider`) to validate tokens on disk and restore the user session.
  - **Logout**: Clears tokens and user data, resetting state to `unauthenticated`.
- **`authStartupProvider`**: A `FutureProvider` used to synchronize app startup with session restoration (optional usage in strict mode).

#### 3. `AuthService.dart` (Infrastructure)
- **Role**: The bridge between the app and the backend API.
- **Responsibilities**:
  - **`loginAsync`**: Posts credentials to `/api/access/token`, parses the `AuthResponse`, and saves the `jwtToken` and `refreshToken` to secure storage.
  - **`restoreSessionAsync`**: Checks for valid tokens on disk. Returns `true` if valid, `false` otherwise.
  - **Storage**: Uses `FlutterSecureStorage` with `AndroidOptions(encryptedSharedPreferences: true)` for secure, persistent storage.

#### 4. `AuthInterceptor.dart` (Network Middleware)
- **Role**: Intercepts all Dio requests to handle authorization automatically.
- **Features**:
  - **Token Injection**: Adds `Authorization: Bearer <token>` to every request header.
  - **Automatic Refresh**: Catches `401 Unauthorized` errors.
    1. Locks the request queue.
    2. Reads the stored `refreshToken`.
    3. Calls the refresh endpoint (`/api/account/identity/refresh-token`).
    4. If successful, updates the stored tokens and **retries the original failed request**.
    5. If refresh fails, propagates the error (triggering logout).

### Authentication Flows

#### Login Flow
1. **User** enters credentials on `LoginScreen`.
2. **`AuthController.login()`** is called.
3. **`AuthService.loginAsync()`** sends POST request.
4. **API** returns `AuthResponse` (JWT + Refresh Token + User).
5. **`AuthService`** writes tokens to `FlutterSecureStorage`.
6. **`Helper`** (in provider) writes User object to storage.
7. **`AuthController`** updates state to `AuthState.authenticated(user)`.
8. **Router** (listening to state) allows navigation to `/home`.

#### Refresh Token Flow
1. **App** makes an API call with an expired JWT.
2. **API** returns `401 Unauthorized`.
3. **`AuthInterceptor`** catches the error.
4. **Interceptor** calls `/refresh-token` with the stored refresh token.
5. **API** returns new tokens.
6. **Interceptor** saves new tokens and retries the original API call.
7. **Result**: Seamless experience; user never knows the token expired.

### Cold Boot Persistence (Strict Mode)

To prevent the "flicker" of the login screen on app restart (Cold Boot), we use a **Strict Initialization** pattern in `main.dart`:

1. **Manual Read**: Before `runApp()`, we await `FlutterSecureStorage.read()` for the token and user.
2. **State Injection**: We create a `ProviderContainer` and **override** the `authControllerProvider` with the pre-loaded state.
   ```dart
   final container = ProviderContainer(
     overrides: [
       if (token != null)
         authControllerProvider.overrideWith(() => AuthController(AuthState.authenticated(user)))
     ]
   );
   ```
3. **Uncontrolled Scope**: We pass this warmed-up container to the app via `UncontrolledProviderScope`.
4. **Router Ready**: The `GoRouter` sees the authenticated state immediately and renders `/home` directly, skipping any loading listeners.

### Directory Structure

```
lib/
├── core/
│   └── network/
│       └── auth_interceptor.dart  <-- Dio Interceptor
├── features/
│   └── auth/
│       ├── models/
│       │   ├── auth_response.dart <-- API DTO
│       │   └── user.dart          <-- User Model
│       ├── providers/
│       │   └── auth_provider.dart <-- Riverpod Controller
│       ├── services/
│       │   └── auth_service.dart  <-- API Calls
│       └── screens/
│           └── login_screen.dart  <-- UI
└── main.dart                      <-- Strict Initialization
```
