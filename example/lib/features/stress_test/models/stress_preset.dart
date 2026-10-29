/// Graph sizes the stress test offers.
enum StressPreset {
  /// 25 nodes.
  tiny(25),

  /// 50 nodes.
  small(50),

  /// 100 nodes.
  medium(100),

  /// 200 nodes.
  large(200),

  /// 500 nodes, laid out on a background isolate where there is one.
  xl(500);

  const StressPreset(this.nodeCount);

  /// Number of generated nodes.
  final int nodeCount;
}
