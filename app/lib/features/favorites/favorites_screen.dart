import 'package:app/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Add this import

// 1. Change StatelessWidget to ConsumerWidget
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  // ❌ Removed: final MobileWebService _webService = MobileWebService();

  @override
  // 2. Add 'WidgetRef ref' to the build parameters
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Favorites Screen'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              print("🚀 Starting Auth Test...");
              
              // 3. Grab the service via Riverpod
              final webService = ref.read(mobileWebServiceProvider);
              
              final success = await webService.logDevMessageAsync("iPhone Auth Test Success!");
              
              if (success) {
                print("🎉 THE CONVENTION WORKS! Server accepted the authorized log.");
              } else {
                print("❌ Auth Test Failed. Check console for 401/403 errors.");
              }
            },
            child: const Text("Run Auth Bridge Test"),
          )
        ],
      ),
    );
  }
}
