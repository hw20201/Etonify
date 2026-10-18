const String lowestProxyTag = 'lowest';
// Legacy synthetic tags are kept only so settings saved by older Etonify
// builds can be migrated without losing the user's selection. They are no
// longer emitted into a sing-box config or shown in the proxy list.
const String lowestOpenProxyTag = 'lowest-open';
const String lowestFreeProxyTag = 'lowest-free';
const String mixedProxyTag = 'mixed';

const List<String> lowestProxyTags = <String>[lowestProxyTag];
const List<String> pinnedProxyTags = <String>[lowestProxyTag];

const Set<String> reservedProxyTags = <String>{
  'select',
  'direct',
  mixedProxyTag,
  lowestProxyTag,
  lowestOpenProxyTag,
  lowestFreeProxyTag,
};

bool isLowestProxyTag(String tag) => tag == lowestProxyTag;

bool isLegacySyntheticProxyTag(String tag) =>
    tag == lowestOpenProxyTag ||
    tag == lowestFreeProxyTag ||
    tag == mixedProxyTag;

bool isSyntheticProxyTag(String tag) =>
    isLowestProxyTag(tag) || isLegacySyntheticProxyTag(tag);

String normalizeProxySelectionTag(String tag) {
  final normalized = tag.trim();
  return isLegacySyntheticProxyTag(normalized) ? lowestProxyTag : normalized;
}

bool isPinnedProxyTag(String tag) => pinnedProxyTags.contains(tag);

bool isReservedProxyTag(String tag) => reservedProxyTags.contains(tag);

int pinnedProxyTagOrder(String tag) {
  final index = pinnedProxyTags.indexOf(tag);
  return index < 0 ? 1 << 30 : index;
}

String lowestProxyBaseLabel(String tag) {
  return 'lowest';
}

String lowestProxyDisplayName(String tag, [String? selectedName]) {
  final label = lowestProxyBaseLabel(tag);
  final selected = selectedName?.trim() ?? '';
  return selected.isEmpty ? label : '$label · $selected';
}

bool lowestProxyAllowsCountry(String tag, String? countryCode) {
  return true;
}
