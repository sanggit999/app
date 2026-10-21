import 'package:flutter_test/flutter_test.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';

void main() {
  test('LanguageRegistry returns default English profile and supported list', () {
    final profile = LanguageRegistry.getProfile('en');
    expect(profile.name, equals('English'));
    expect(profile.ttsLocale, equals('en-US'));
    expect(profile.sttLocale, equals('en_US'));
    expect(LanguageRegistry.supportedLanguages.length, greaterThanOrEqualTo(2));
  });

  test('LanguageRegistry returns Vietnamese profile correctly', () {
    final vi = LanguageRegistry.getProfile('vi');
    expect(vi.name, equals('Vietnamese'));
    expect(vi.ttsLocale, equals('vi-VN'));
  });

  test('LanguageRegistry falls back to English when code is unknown', () {
    final unknown = LanguageRegistry.getProfile('unknown_code');
    expect(unknown.code, equals('en'));
  });
}
