import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/routing/app_router.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'WheelyTrails',
      theme: AppTheme.LightTheme,
      darkTheme: AppTheme.DarkTheme,
      routerConfig: goRouter,
    );
  }
}
