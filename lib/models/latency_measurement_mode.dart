enum LatencyMeasurementMode {
  unifiedUrlTest,
  realUrl;

  static LatencyMeasurementMode fromStorage(Object? value) =>
      switch (value?.toString()) {
        'realUrl' || 'real_url' => LatencyMeasurementMode.realUrl,
        _ => LatencyMeasurementMode.unifiedUrlTest,
      };
}
