import 'package:flutter_test/flutter_test.dart';
import 'package:goabusconnect/core/services/gps_service.dart';

void main() {
  test('GPS fixes reject invalid coordinates for map markers', () {
    final valid = GpsFix(
      latitude: 15.5,
      longitude: 73.8,
      recordedAt: DateTime.utc(2026, 11, 18),
      accuracyMeters: 5,
    );
    final invalid = GpsFix(
      latitude: 95,
      longitude: 73.8,
      recordedAt: DateTime.utc(2026, 11, 18),
      accuracyMeters: 5,
    );
    expect(valid.hasValidCoordinates, isTrue);
    expect(invalid.hasValidCoordinates, isFalse);
  });

  test('unavailable GPS service never reports a live feed', () async {
    const gps = UnavailableGPSService();
    expect(gps.isConnected, isFalse);
    expect(gps.lastUpdated, isNull);
    await expectLater(gps.start('bus-id'), throwsUnsupportedError);
  });
}
