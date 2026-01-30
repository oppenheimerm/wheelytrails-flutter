enum SurfaceType {
  none(0),
  paved(1),
  compactGravel(2),
  looseGravel(4),
  grass(8),
  dirt(16),
  sand(32),
  woodchips(64);

  final int value;
  const SurfaceType(this.value);
}

// Helper to calculate total value from a list of selected types
int calculateTotalSurfaceValue(List<SurfaceType> selectedTypes) {
  int total = 0;
  for (var type in selectedTypes) {
    total |= type.value;
  }
  return total;
}
