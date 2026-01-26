String normalizeActivationCode(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[\u2010-\u2015\u2212]'), '-')
      .toUpperCase();
}

String normalizeTouristCode(String input) {
  return normalizeActivationCode(input);
}
