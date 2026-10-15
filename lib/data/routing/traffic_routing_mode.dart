enum TrafficRoutingMode {
  rules,
  global;

  String get storageValue => switch (this) {
    TrafficRoutingMode.rules => 'rules',
    TrafficRoutingMode.global => 'global',
  };

  static TrafficRoutingMode fromStorage(Object? value) =>
      value?.toString().trim() == 'global'
      ? TrafficRoutingMode.global
      : TrafficRoutingMode.rules;
}
