import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/features/home/home_connection_button.dart';
import 'package:meow_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('startup morph keeps the rendered glow continuous', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ConnectionButton(
            connected: true,
            connecting: false,
            resolvingProxy: false,
            statusLabel: '',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final animation = tester
        .widget<TweenAnimationBuilder<ConnectionButtonShape>>(
          find.byType(TweenAnimationBuilder<ConnectionButtonShape>),
        );
    final context = tester.element(find.byType(ConnectionButton));
    double? previous;
    var largestStep = 0.0;

    // The near-connecting part of the five-to-eight-lobe morph used to make
    // drawShadow alternate between visibly different shadow intensities, even
    // when the runtime state, color and animation direction stayed unchanged.
    for (var frame = 0; frame <= 100; frame++) {
      final phase = 1 + frame / 1000;
      final shape = ConnectionButtonShape(
        phase: phase,
        rotation: 0,
        emphasis: .52 + (phase - 1) * .64,
      );
      final boundary =
          animation.builder(context, shape, animation.child) as RepaintBoundary;
      final transform = boundary.child! as Transform;
      final paint = transform.child! as CustomPaint;
      final intensity = await tester.runAsync(
        () => _haloIntensity(paint.painter!, transform.transform.storage[0]),
      );
      expect(intensity, isNotNull);
      expect(
        intensity!,
        greaterThan(0),
        reason: 'the glow must remain visible',
      );
      if (previous != null) {
        largestStep = math.max(largestStep, (intensity - previous).abs());
      }
      previous = intensity;
    }
    // Allow sub-level raster quantization, not the old ~2.3/255 jumps for a 0.001 phase
    // step. Sampling a broad outer ring avoids individual antialiased edges.
    expect(largestStep, lessThan(.5));
  });
}

Future<double> _haloIntensity(CustomPainter painter, double scale) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xfff1faf5), BlendMode.src);
  canvas.translate(256, 256);
  canvas.scale(3 * scale);
  canvas.translate(-74, -74);
  painter.paint(canvas, const Size.square(148));
  final picture = recorder.endRecording();
  final image = await picture.toImage(512, 512);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var total = 0.0;
    var count = 0;
    for (var y = 0; y < 512; y++) {
      for (var x = 0; x < 512; x++) {
        final squaredRadius = (x - 256) * (x - 256) + (y - 256) * (y - 256);
        if (squaredRadius > 240 * 240 &&
            squaredRadius < 255 * 255 &&
            (x - 256).abs() > 150) {
          total += 241 - data.getUint8((y * 512 + x) * 4);
          count++;
        }
      }
    }
    return total / count;
  } finally {
    image.dispose();
    picture.dispose();
  }
}
