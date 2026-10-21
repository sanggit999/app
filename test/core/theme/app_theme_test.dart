import 'package:flutter_test/flutter_test.dart';
import 'package:echo_lingua/core/theme/app_theme.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme defines consistent primary colors and dark/light themes', () {
    expect(AppColors.primary, isNotNull);
    expect(AppTheme.darkTheme.primaryColor, equals(AppColors.primary));
    expect(AppTheme.lightTheme.primaryColor, equals(AppColors.primary));
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
    expect(AppTheme.lightTheme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
  });
}
