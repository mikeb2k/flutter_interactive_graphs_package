// Renders the screenshots and the GIF of the README into `doc/images/`, from the example app:
//
//   cd example && flutter test tool/doc_images_test.dart
//
// It needs `ffmpeg` on the PATH for the GIF. Not part of the test suite (it is outside `test/`).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs_example/app.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:interactive_graphs_example/features/showcase/providers/showcase_provider.dart';
import 'package:interactive_graphs_example/features/showcase/views/showcase_view.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final output = Directory(Platform.environment['DOC_IMAGES_OUT'] ?? '../doc/images');
  final screen = GlobalKey();
  const frame = Duration(milliseconds: 50);

  // Tests draw every text as boxes unless real fonts are loaded
  Future<void> loadFonts() async {
    final fonts = Directory('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts');
    final roboto = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      final bytes = await File('${fonts.path}/Roboto-$weight.ttf').readAsBytes();
      roboto.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    final iconBytes = await File('${fonts.path}/MaterialIcons-Regular.otf').readAsBytes();
    final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(iconBytes)));
    await Future.wait([roboto.load(), icons.load()]);
  }

  setUpAll(() async {
    await loadFonts();
    output.createSync(recursive: true);
  });

  /// Shows the example in dark mode on a screen of [size] logical pixels.
  Future<ProviderContainer> pumpApp(WidgetTester tester, Size size, {required double pixelRatio}) async {
    tester.view
      ..physicalSize = size * pixelRatio
      ..devicePixelRatio = pixelRatio;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    debugDisableShadows = false;
    await tester.pumpWidget(
      ProviderScope(
        child: RepaintBoundary(key: screen, child: const ExampleApp()),
      ),
    );
    return ProviderScope.containerOf(tester.element(find.byType(ShowcaseView)));
  }

  /// Lets [duration] pass, one frame at a time.
  Future<void> play(WidgetTester tester, Duration duration, {Future<void> Function()? onFrame}) async {
    final end = tester.binding.clock.now().add(duration);
    while (tester.binding.clock.now().isBefore(end)) {
      await tester.pump(frame);
      await onFrame?.call();
    }
  }

  /// The screen as it is drawn now.
  Future<ui.Image> shot(WidgetTester tester) async {
    final boundary = screen.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: tester.view.devicePixelRatio));
    return image!;
  }

  Future<void> savePng(WidgetTester tester, String name) async {
    final image = await shot(tester);
    await tester.runAsync(() async {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${output.path}/$name').writeAsBytes(bytes!.buffer.asUint8List());
    });
    image.dispose();
  }

  /// Takes the app down and lets its timers run out, as the test framework demands.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    debugDisableShadows = true;
  }

  testWidgets('demo-phone.png: the order on its way, on a phone', (tester) async {
    await pumpApp(tester, const Size(390, 844), pixelRatio: 3);
    await play(tester, const Duration(seconds: 2));
    await tester.tap(find.byTooltip(ShowcaseCopy.playOrder));
    await play(tester, const Duration(milliseconds: 4200));
    await savePng(tester, 'demo-phone.png');
    await close(tester);
  });

  testWidgets('demo-phone-details.png: an expanded step, on a phone', (tester) async {
    await pumpApp(tester, const Size(390, 844), pixelRatio: 3);
    await play(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Sorting hub'));
    await play(tester, const Duration(seconds: 4));
    await savePng(tester, 'demo-phone-details.png');
    await close(tester);
  });

  testWidgets('demo-desktop.png: the order on its way, in a window', (tester) async {
    await pumpApp(tester, const Size(1280, 720), pixelRatio: 2);
    await play(tester, const Duration(seconds: 2));
    await tester.tap(find.byTooltip(ShowcaseCopy.playOrder));
    await play(tester, const Duration(milliseconds: 4200));
    await savePng(tester, 'demo-desktop.png');
    await close(tester);
  });

  testWidgets('demo-interaction.gif: the start of the guided tour', (tester) async {
    // 720 x 540 pixels: wide enough for the header, tall enough for the caption and the toolbar
    const size = Size(800, 600);
    const pixelRatio = 0.9;
    final container = await pumpApp(tester, size, pixelRatio: pixelRatio);
    await play(tester, const Duration(seconds: 2));
    final frames = File('${Directory.systemTemp.createTempSync('doc_images').path}/frames.rgba');
    final sink = frames.openSync(mode: FileMode.write);

    Future<void> record() async {
      final image = await shot(tester);
      final bytes = await tester.runAsync(() => image.toByteData());
      sink.writeFromSync(bytes!.buffer.asUint8List());
      image.dispose();
    }

    // The graph grows, the order runs while the camera pans along, and the camera fits it again
    await tester.tap(find.text(ShowcaseCopy.playTour));
    await play(tester, const Duration(milliseconds: 17800), onFrame: record);
    sink.closeSync();
    expect(container.read(showcaseProvider).isTouring, isTrue);

    // 64 colors are plenty for the flat dark UI and keep the file under pub.dev's 4 MB limit
    const filter = '[0:v]split[a][b];[a]palettegen=max_colors=64:stats_mode=diff[p];[b][p]paletteuse=dither=none';
    final arguments = [
      ...['-y', '-v', 'error', '-f', 'rawvideo', '-pixel_format', 'rgba'],
      ...['-video_size', '${(size.width * pixelRatio).round()}x${(size.height * pixelRatio).round()}'],
      ...['-framerate', '${Duration.millisecondsPerSecond ~/ frame.inMilliseconds}', '-i', frames.path],
      ...['-filter_complex', filter, '${output.path}/demo-interaction.gif'],
    ];
    final result = await tester.runAsync(() => Process.run('ffmpeg', arguments));
    frames.parent.deleteSync(recursive: true);
    expect(result!.exitCode, 0, reason: '${result.stderr}');
    await close(tester);
  });
}
