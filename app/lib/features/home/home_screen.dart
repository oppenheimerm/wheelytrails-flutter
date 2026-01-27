import 'package:app/data/mock_trails.dart';
import 'package:app/models/trail.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover Trails',
          style: GoogleFonts.figtree(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockTrails.length,
        itemBuilder: (context, index) {
          final trail = mockTrails[index];
          return TrailCard(trail: trail);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }
}

class TrailCard extends StatelessWidget {
  const TrailCard({super.key, required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      // No margin here because we use ListView.separated
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.network(
              trail.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trail.name,
                        style: GoogleFonts.figtree(
                          textStyle: theme.textTheme.titleLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        trail.difficulty.name.toUpperCase(),
                        style: GoogleFonts.figtree(
                          textStyle: theme.textTheme.labelSmall,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Requested: Use colorScheme.primary for background
                      backgroundColor: theme.colorScheme.primary,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trail.location,
                      style: GoogleFonts.figtree(
                        textStyle: theme.textTheme.bodyMedium,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trail.distance} km',
                      style: GoogleFonts.figtree(
                        textStyle: theme.textTheme.bodyMedium,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
