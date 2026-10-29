import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_state.dart';
import 'package:interactive_graphs_example/features/stress_test/providers/stress_test_provider.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_controls_card.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_graph_viewer.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_loading_overlay.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_zoom_toolbar.dart';
import 'package:material_ui/material_ui.dart';

/// Stress test: large random graphs with a node count picker, layout switch, regeneration, debug
/// bounds and batched edge painting. Graphs of 400 nodes or more are laid out on a background
/// isolate (except on the web).
class StressTestView extends ConsumerStatefulWidget {
  /// Creates the screen.
  const StressTestView({super.key});

  /// Route to this screen.
  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const StressTestView());

  @override
  ConsumerState<StressTestView> createState() => _StressTestViewState();
}

class _StressTestViewState extends ConsumerState<StressTestView> {
  final GlobalKey _controlsKey = GlobalKey();
  late GraphViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController(ref.read(stressTestProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stressTestProvider);
    final notifier = ref.read(stressTestProvider.notifier);
    ref.listen(stressTestProvider, _onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback(_reserveControlsHeight);
    final graph = state.stressGraph.graph;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: StressTestGraphViewer(
                controller: _controller,
                nodeData: state.stressGraph.nodeData,
                showDebugBounds: state.showDebugBounds,
                batchedEdges: state.batchedEdges,
              ),
            ),
            Positioned.fill(child: StressTestLoadingOverlay(controller: _controller)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: _onControlsResized,
                child: SizeChangedLayoutNotifier(
                  child: StressTestControlsCard(
                    key: _controlsKey,
                    controller: _controller,
                    selectedPreset: state.preset,
                    onPresetSelected: notifier.selectPreset,
                    selectedLayoutAlgorithm: state.layoutAlgorithm,
                    onLayoutAlgorithmSelected: notifier.selectLayoutAlgorithm,
                    nodeCount: graph.nodes.length,
                    edgeCount: graph.edges.length,
                    showDebugBounds: state.showDebugBounds,
                    onToggleDebugBounds: notifier.toggleDebugBounds,
                    batchedEdges: state.batchedEdges,
                    onToggleBatchedEdges: notifier.toggleBatchedEdges,
                    onRegenerate: notifier.regenerate,
                    onNavigateBack: Navigator.of(context).pop,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: StressTestZoomToolbar(
                controller: _controller,
                expanded: state.toolbarExpanded,
                onToggleExpanded: notifier.toggleToolbar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  GraphViewerController _createController(StressTestState state) =>
      GraphViewerController(graph: state.stressGraph.graph, layoutConfig: state.layoutConfig);

  /// A new graph gets a fresh controller, which resets zoom, pan and the initial fit like Kuiver's
  /// keyed viewer state; a new layout algorithm is handed to the current one.
  void _onStateChanged(StressTestState? previous, StressTestState next) {
    if (previous?.stressGraph != next.stressGraph) {
      final old = _controller;
      setState(() {
        _controller = _createController(next)..updateContentOffset(old.contentOffset);
      });
      // The viewer lets go of the old controller while rebuilding
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    } else if (previous?.layoutAlgorithm != next.layoutAlgorithm) {
      _controller.layoutConfig = next.layoutConfig;
    }
  }

  bool _onControlsResized(SizeChangedLayoutNotification notification) {
    WidgetsBinding.instance.addPostFrameCallback(_reserveControlsHeight);
    return true;
  }

  /// Reserves the height of the controls card so that centering keeps the graph clear of it.
  void _reserveControlsHeight(Duration _) {
    if (!mounted) return;
    final height = _controlsKey.currentContext?.size?.height;
    if (height != null) _controller.updateContentOffset(Offset(0, height));
  }
}
