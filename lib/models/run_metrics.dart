/// Metrics for a single run (row) in the wrap layout.
/// Stores the dimensions and child count of a completed run.
class RunMetrics {
  const RunMetrics(this.mainAxisExtent, this.crossAxisExtent, this.childCount);

  final double mainAxisExtent;
  final double crossAxisExtent;
  final int childCount;
}
