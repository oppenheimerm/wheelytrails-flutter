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

#### 3. `AuthService.dart` (Singleton Infrastructure)
- **Role**: The centralized "Source of Truth" for authentication.
- **Pattern**: Implements the **Singleton** pattern (`AuthService.instance`) to ensure a single access point for token management.
- **Responsibilities**:
  - **`refresh()`**: Centralized logic to read the refresh token, call the API, and update storage.
  - **`getAccessToken()`**: helper to retrieve the valid JWT.
  - **Storage**: Manages `FlutterSecureStorage` internally.

#### 4. `AuthInterceptor.dart` (Simplified Middleware)
- **Role**: Lightweight interceptor for token injection only.
- **Changes**: 
  - **Removed**: The complex `QueuedInterceptor` logic has been removed to avoid deadlocks.
  - **Responsibility**: Now strictly adds `Authorization: Bearer <token>` to headers. It **does not** handle refreshes or retries anymore.

#### 5. `BaseApiService.dart` (New Core Layer)
- **Role**: Abstract base class for all API services (e.g., `TrailApiService`).
- **Features**:
  - **`safeRequest()`**: A robust wrapper for API calls that handles:
    1. **Auth Expiry**: on 401, calls `AuthService.refresh()` and retries once.
    2. **Transient Errors**: Retries on 5xx or network timeouts with backoff.
    3. **Logging**: logs failures to `/api/dev/log-trail`.
  - **Drafts**: If all retries fail, services can fallback to local storage (implemented in `TrailApiService`).

### Authentication & Upload Flows

#### Login Flow
(Same as before, but handled via `AuthService.instance`)

#### Robust Upload & Refresh Flow (Explicit)
Instead of relying on a hidden interceptor queue, services now use `safeRequest()`:
1. **Service** calls `safeRequest()`.
2. **`safeRequest`** attaches the token.
3. **If 401 occurs**:
   - Explicitly calls `await AuthService.instance.refresh()`.
   - If successful, retries the request immediately.
   - If failed, throws error.
4. **If Network Error (500/Timeout)**:
   - Retries up to 3 times with exponential backoff.
5. **If All Fails**:
   - `TrailApiService` catches the final exception.
   - Saves the payload to **Local Drafts** (`/draft_trails`).
   - User gets a "Saved to Drafts" notification.

### Directory Structure

```
lib/
├── core/
│   └── network/
│       ├── auth_interceptor.dart  <-- Token Injection
│       └── base_api_service.dart  <-- Robust Wrapper
├── features/
│   └── auth/
│       ├── models/
│       │   ├── auth_response.dart <-- API DTO
│       │   └── user.dart          <-- User Model
│       ├── providers/
│       │   └── auth_provider.dart <-- Riverpod Controller
│       ├── services/
│       │   └── auth_service.dart  <-- Singleton Logic
│       └── screens/
│           └── login_screen.dart  <-- UI
└── main.dart                      <-- Strict Initialization
```
