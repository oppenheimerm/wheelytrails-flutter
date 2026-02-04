import 'package:app/models/trail.dart';

final List<Trail> mockTrails = [
  const Trail(
    id: '1',
    name: 'Sunny Lakeside Path',
    description:
        'A gentle paved path around the serene lake, perfect for a relaxing afternoon roll.',
    surfaceType: SurfaceType.paved,
    location: 'Lakeview Park',
    distance: 3.5,
    difficulty: DifficultyLevel.easy,
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=2560&auto=format&fit=crop',
  ),
  const Trail(
    id: '2',
    name: 'Forest Glade Loop',
    description:
        'Immerse yourself in nature with this gravel loop through the dense forest.',
    surfaceType: SurfaceType.gravel,
    location: 'Whispering Woods',
    distance: 5.2,
    difficulty: DifficultyLevel.moderate,
    imageUrl:
        'https://images.unsplash.com/photo-1448375240586-dfd8d395ea6c?q=80&w=2670&auto=format&fit=crop',
  ),
  const Trail(
    id: '3',
    name: 'Rocky Ridge Climb',
    description:
        'Challenge your skills on this uneven dirt track with stunning panoramic views.',
    surfaceType: SurfaceType.dirt,
    location: 'Highland Peaks',
    distance: 8.0,
    difficulty: DifficultyLevel.hard,
    imageUrl:
        'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=2670&auto=format&fit=crop',
  ),
  const Trail(
    id: '4',
    name: 'Meadow Breeze',
    description:
        'Roll through open grassy fields with wildflowers on this flat and wide trail.',
    surfaceType: SurfaceType.grass,
    location: 'Sunnydale Meadows',
    distance: 2.1,
    difficulty: DifficultyLevel.easy,
    imageUrl:
        'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=2574&auto=format&fit=crop',
  ),
  const Trail(
    id: '5',
    name: 'Coastal Boardwalk',
    description:
        'Enjoy the ocean breeze on this sturdy wooden boardwalk along the coast.',
    surfaceType: SurfaceType.paved,
    location: 'Seaside Cliffs',
    distance: 4.8,
    difficulty: DifficultyLevel.easy,
    imageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2673&auto=format&fit=crop',
  ),
];
