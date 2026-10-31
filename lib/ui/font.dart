import 'package:material_ui/material_ui.dart';

enum _HanVariant { simplified, traditional, japanese, korean }

// The system fallback picks Han glyph forms by the UI locale, which draws
// Chinese proxy names with Japanese forms under an English UI on Windows.
const _hanFamilies = <TargetPlatform, Map<_HanVariant, List<String>>>{
  TargetPlatform.windows: {
    _HanVariant.simplified: ['Microsoft YaHei UI'],
    _HanVariant.traditional: ['Microsoft JhengHei UI'],
    _HanVariant.japanese: ['Yu Gothic UI', 'Meiryo UI'],
    _HanVariant.korean: ['Malgun Gothic'],
  },
  TargetPlatform.macOS: {
    _HanVariant.simplified: ['PingFang SC'],
    _HanVariant.traditional: ['PingFang TC'],
    _HanVariant.japanese: ['Hiragino Sans'],
    _HanVariant.korean: ['Apple SD Gothic Neo'],
  },
};

_HanVariant _hanVariantOf(Iterable<Locale> locales) {
  for (final locale in locales) {
    switch (locale.languageCode) {
      case 'zh':
        return _isTraditional(locale)
            ? _HanVariant.traditional
            : _HanVariant.simplified;
      case 'ja':
        return _HanVariant.japanese;
      case 'ko':
        return _HanVariant.korean;
    }
  }
  return _HanVariant.simplified;
}

bool _isTraditional(Locale locale) => switch (locale.scriptCode) {
  'Hant' => true,
  'Hans' => false,
  _ => const {'TW', 'HK', 'MO'}.contains(locale.countryCode),
};

List<String> appFontFamilyFallback({
  required TargetPlatform platform,
  required Iterable<Locale> locales,
  String? fontFamily,
}) {
  final base = Typography.material2021(platform: platform).black.bodyMedium!;
  return [
    if (fontFamily != null) ?base.fontFamily,
    ...?base.fontFamilyFallback,
    ...?_hanFamilies[platform]?[_hanVariantOf(locales)],
  ];
}
