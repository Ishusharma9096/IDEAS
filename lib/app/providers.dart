import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/gps_service.dart';
import '../features/transit/data/transit_repository.dart';

final transitRepositoryProvider = Provider<TransitRepository>(
  (ref) => TransitRepository.instance,
);

final gpsServiceProvider = Provider<GPSService>((ref) {
  final service = DeviceGPSService();
  ref.onDispose(service.dispose);
  return service;
});
