import 'package:flutter_test/flutter_test.dart';
import 'package:echo_lingua/core/errors/failures.dart';

void main() {
  test('ServerFailure holds message and supports value equality', () {
    const f1 = ServerFailure(message: 'Connection failed');
    const f2 = ServerFailure(message: 'Connection failed');
    const f3 = ServerFailure(message: 'Different error');

    expect(f1, equals(f2));
    expect(f1 == f3, isFalse);
    expect(f1.props, equals(['Connection failed', null]));
  });

  test('AudioFailure supports message and equality', () {
    const a1 = AudioFailure(message: 'Mic permission denied');
    const a2 = AudioFailure(message: 'Mic permission denied');

    expect(a1, equals(a2));
  });
}
