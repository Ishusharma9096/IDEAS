import 'package:flutter_test/flutter_test.dart';
import 'package:goabusconnect/features/transit/data/transit_repository.dart';
import 'package:goabusconnect/features/transit/domain/transit_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'saved journeys, recent searches and complaints persist locally',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = TransitRepository.instance;
      await repository.initialize();
      repository.toggleSaved('demo-ktc-101');
      repository.recordSearch('Panaji', 'Margao', DateTime(2026, 11, 17));
      repository.addComplaint(
        PassengerComplaint(
          id: 'local-test',
          busId: 'demo-ktc-101',
          busLabel: 'DEMO KTC-101',
          personType: 'Driver',
          category: 'Safety',
          description: 'Test complaint',
          submittedAt: DateTime.utc(2026, 11, 17),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getStringList('saved_bus_ids'),
        contains('demo-ktc-101'),
      );
      expect(preferences.getStringList('recent_journeys'), isNotEmpty);
      expect(preferences.getStringList('demo_complaints'), isNotEmpty);
    },
  );

  test('demo search only returns explicitly labelled demo records', () {
    final results = TransitRepository.instance.search('Panaji', 'Margao');
    expect(results, isNotEmpty);
    expect(
      results.every(
        (bus) => bus.verification == VerificationStatus.unverifiedDemo,
      ),
      isTrue,
    );
  });
}
