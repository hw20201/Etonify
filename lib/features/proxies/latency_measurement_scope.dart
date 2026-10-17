import 'package:flutter/widgets.dart';
import 'package:meow_client/models/latency_measurement_mode.dart';

class LatencyMeasurementScope extends InheritedWidget {
  const LatencyMeasurementScope({
    super.key,
    required this.mode,
    required super.child,
  });

  final LatencyMeasurementMode mode;

  static LatencyMeasurementMode? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LatencyMeasurementScope>()
      ?.mode;

  @override
  bool updateShouldNotify(LatencyMeasurementScope oldWidget) =>
      mode != oldWidget.mode;
}
