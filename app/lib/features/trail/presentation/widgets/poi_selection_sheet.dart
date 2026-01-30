import 'package:app/features/trail/models/trail_models.dart';
import 'package:flutter/material.dart';

class PoiSelectionSheet extends StatelessWidget {
  final Function(PoiType) onPoiSelected;

  const PoiSelectionSheet({super.key, required this.onPoiSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Point of Interest',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: poiTypes.length,
              itemBuilder: (context, index) {
                final poi = poiTypes[index];
                return InkWell(
                  onTap: () {
                    onPoiSelected(poi);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Placeholder icon logic - mapping codes to icons
                        Icon(
                          _getIconForType(poi.code),
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            poi.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String code) {
    switch (code) {
      case 'VIEW':
        return Icons.landscape;
      case 'REST':
        return Icons.chair;
      case 'INFO':
        return Icons.info;
      case 'FOOD':
        return Icons.fastfood;
      case 'FDRT':
        return Icons.restaurant;
      case 'FDBR':
        return Icons.local_bar;
      case 'SHOP':
        return Icons.shopping_bag;
      case 'SPRT':
        return Icons.sports_soccer;
      case 'TOIL':
        return Icons.wc;
      case 'ACCS':
        return Icons.accessible;
      case 'HIST':
        return Icons.museum;
      case 'BEAC':
        return Icons.beach_access;
      case 'DOCK':
        return Icons.deck;
      case 'LAKE':
        return Icons.water;
      case 'RIVR':
        return Icons.kayaking;
      case 'WATR':
        return Icons.water_drop;
      case 'MNTN':
        return Icons.terrain;
      case 'NATU':
        return Icons.forest;
      case 'OBST':
        return Icons.report_problem;
      case 'CNST':
        return Icons.construction;
      case 'OBSV':
        return Icons.visibility;
      case 'HOSP':
        return Icons.local_hospital;
      case 'FSTN':
        return Icons.medical_services;
      case 'OTHR':
        return Icons.place;
      default:
        return Icons.location_on;
    }
  }
}
