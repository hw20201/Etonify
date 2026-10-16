enum PublicIpSource {
  ipQuery,
  ipApi,
  ipWho;

  static PublicIpSource fromStorage(Object? value) =>
      switch (value?.toString()) {
        'ipApi' || 'ip-api' => PublicIpSource.ipApi,
        'ipWho' || 'ipwho' => PublicIpSource.ipWho,
        _ => PublicIpSource.ipQuery,
      };
}
