import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_spec.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/port_dot.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_card.dart';
import 'package:material_ui/material_ui.dart';

/// Node of one order step: its [StepCard] with the edge anchors on its sides. Pops in when it
/// enters the graph (after [appearDelay]), shrinks away when [leaving] and fades back when
/// [dimmed].
class StepNode extends StatefulWidget {
  /// Creates the node of [spec].
  const StepNode({
    super.key,
    required this.spec,
    required this.status,
    required this.expanded,
    required this.leaving,
    required this.dimmed,
    required this.isSelected,
    required this.isHovered,
    required this.isDragging,
    required this.ports,
    required this.appearDelay,
  });

  /// The step.
  final StepSpec spec;

  /// Its status.
  final StepStatus status;

  /// Whether the details are shown.
  final bool expanded;

  /// Whether the node is about to be removed.
  final bool leaving;

  /// Whether another node or edge has the focus.
  final bool dimmed;

  /// Whether the viewer has the node selected.
  final bool isSelected;

  /// Whether the pointer is over the node.
  final bool isHovered;

  /// Whether the node is being dragged.
  final bool isDragging;

  /// Anchor ids edges are attached to, drawn as dots.
  final Set<String> ports;

  /// Delay before popping in, to stagger a batch of nodes.
  final Duration appearDelay;

  @override
  State<StepNode> createState() => _StepNodeState();
}

class _StepNodeState extends State<StepNode> with SingleTickerProviderStateMixin {
  late final AnimationController _appear = AnimationController.unbounded(vsync: this);
  final SpringDescription _popSpring = SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: 0.8);
  Timer? _appearTimer;
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    _started = true;
    _syncAppearance();
  }

  @override
  void didUpdateWidget(StepNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leaving != widget.leaving) _syncAppearance();
  }

  @override
  void dispose() {
    _appearTimer?.cancel();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ports = widget.ports;
    return AnimatedBuilder(
      animation: _appear,
      builder: _appearing,
      child: AnimatedScale(
        scale: _lift(),
        duration: _duration(150),
        child: AnimatedOpacity(
          opacity: _alpha(),
          duration: _duration(250),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StepCard(
                spec: widget.spec,
                status: widget.status,
                expanded: widget.expanded,
                isSelected: widget.isSelected,
                isHovered: widget.isHovered,
                isDragging: widget.isDragging,
              ),
              Positioned(
                left: -5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: PortDot(id: 'left', visible: ports.contains('left')),
                ),
              ),
              Positioned(
                right: -5,
                top: 0,
                bottom: 0,
                child: Center(
                  child: PortDot(id: 'right', visible: ports.contains('right')),
                ),
              ),
              Positioned(
                top: -5,
                left: 0,
                right: 0,
                child: Center(
                  child: PortDot(id: 'top', visible: ports.contains('top')),
                ),
              ),
              Positioned(
                bottom: -5,
                left: 0,
                right: 0,
                child: Center(
                  child: PortDot(id: 'bottom', visible: ports.contains('bottom')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appearing(BuildContext context, Widget? child) {
    final value = _appear.value;
    return Opacity(
      opacity: value.clamp(0.0, 1.0),
      child: Transform.scale(scale: value, child: child),
    );
  }

  void _syncAppearance() {
    _appearTimer?.cancel();
    if (widget.leaving) {
      if (_reduceMotion) {
        _appear.value = 0;
      } else {
        _appear.animateTo(0, duration: const Duration(milliseconds: 150), curve: Curves.easeIn);
      }
      return;
    }
    if (_reduceMotion) {
      _appear.value = 1;
      return;
    }
    _appearTimer = Timer(widget.appearDelay, _popIn);
  }

  void _popIn() {
    if (!mounted) return;
    _appear.animateWith(SpringSimulation(_popSpring, _appear.value, 1, 0));
  }

  double _lift() {
    if (widget.isDragging) return 1.04;
    return 1;
  }

  double _alpha() {
    if (widget.dimmed) return 0.35;
    return 1;
  }

  Duration _duration(int millis) {
    if (_reduceMotion) return Duration.zero;
    return Duration(milliseconds: millis);
  }
}
