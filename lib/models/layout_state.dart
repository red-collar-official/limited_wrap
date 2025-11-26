/// Accumulated state during layout calculation.
/// Tracks current run metrics, total extents, and row information for maxLines support.
class LayoutState {
  double mainAxisExtent = 0;
  double crossAxisExtent = 0;
  double runMainAxisExtent = 0;
  double runCrossAxisExtent = 0;
  int childCount = 0;
  int currentRow = 0;
  double currentRowWidth = 0;
}
