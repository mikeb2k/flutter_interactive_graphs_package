import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Tells pointer users once that Ctrl+scroll zooms, on the platforms where plain scrolling pans.
class ZoomHint extends StatefulWidget {
  /// Creates the hint around [child].
  const ZoomHint({super.key, required this.message, required this.child});

  /// The hint text.
  final String message;

  /// The screen.
  final Widget child;

  @override
  State<ZoomHint> createState() => _ZoomHintState();
}

class _ZoomHintState extends State<ZoomHint> {
  @override
  void initState() {
    super.initState();
    if (_scrollPans) WidgetsBinding.instance.addPostFrameCallback(_show);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  bool get _scrollPans =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.macOS || TargetPlatform.linux || TargetPlatform.windows => true,
        _ => false,
      };

  void _show(Duration _) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(widget.message), behavior: SnackBarBehavior.floating),
    );
  }
}
