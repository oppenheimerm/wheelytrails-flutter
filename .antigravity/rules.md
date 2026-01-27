# WheelyTrails Migration Standards

## Context
- @wheel-trails: Legacy C# / MAUI / ASP.NET Source.
- @wheelytrails-flutter: Target Flutter / Dart Source.

## Frontend Rules (Flutter)
- State Management: Riverpod (use Notifiers, avoid legacy Providers).
- UI: Material 3, Responsive Layouts (Admin Web + Mobile).
- Networking: Use `dio` with custom interceptors for backend auth.

## Migration Protocol
- Step 1: Analyze C# file.
- Step 2: Generate "Implementation Plan" artifact.
- Step 3: Wait for User Approval.
- Step 4: Execute code generation in Dart.