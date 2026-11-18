import 'package:flutter/foundation.dart';

enum BusOwnership { government, private }

enum VerificationStatus { unverifiedDemo, verified, expired, reported }

@immutable
class BusService {
  const BusService({
    required this.id,
    required this.operator,
    required this.identifier,
    required this.ownership,
    required this.from,
    required this.to,
    required this.stops,
    required this.source,
    required this.verification,
    this.departure,
    this.arrival,
    this.fare,
    this.gpsAvailable = false,
  });
  final String id, operator, identifier, from, to, source;
  final BusOwnership ownership;
  final VerificationStatus verification;
  final List<String> stops;
  final String? departure, arrival;
  final double? fare;
  final bool gpsAvailable;
}

@immutable
class BusStop {
  const BusStop({required this.id, required this.name, required this.area});
  final String id, name, area;
}

@immutable
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.stops,
  });
  final String id, name, from, to;
  final List<String> stops;
}

@immutable
class JourneySearchRecord {
  const JourneySearchRecord({
    required this.from,
    required this.to,
    required this.date,
    required this.searchedAt,
  });
  final String from, to;
  final DateTime date, searchedAt;
}

@immutable
class PassengerComplaint {
  const PassengerComplaint({
    required this.id,
    required this.busId,
    required this.busLabel,
    required this.personType,
    required this.category,
    required this.description,
    required this.submittedAt,
    this.occurredAt,
    this.status = 'submitted',
  });
  final String id, busId, busLabel, personType, category, description;
  final DateTime submittedAt;
  final DateTime? occurredAt;
  final String status;
  Map<String, Object?> toJson() => {
    'id': id,
    'busId': busId,
    'busLabel': busLabel,
    'personType': personType,
    'category': category,
    'description': description,
    'submittedAt': submittedAt.toIso8601String(),
    'occurredAt': occurredAt?.toIso8601String(),
    'status': status,
  };
  factory PassengerComplaint.fromJson(Map<String, Object?> json) =>
      PassengerComplaint(
        id: json['id']! as String,
        busId: json['busId']! as String,
        busLabel: json['busLabel']! as String,
        personType: json['personType']! as String,
        category: json['category']! as String,
        description: json['description']! as String,
        submittedAt: DateTime.parse(json['submittedAt']! as String),
        occurredAt: json['occurredAt'] == null
            ? null
            : DateTime.parse(json['occurredAt']! as String),
        status: json['status'] as String? ?? 'submitted',
      );
}
