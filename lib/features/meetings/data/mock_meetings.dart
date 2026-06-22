import '../domain/entities/meeting_entity.dart';

/// PROTOTYPE MODE: shared mock meeting data used by both the meetings list
/// and active-meeting screens so they stay consistent without a backend.
/// Re-connect both screens to MeetingsBloc/MeetingsRepository once the
/// backend is ready.
abstract final class MockMeetings {
  static final List<MeetingEntity> all = [
    MeetingEntity(
      id: 'm1',
      partnerId: 'c1',
      partnerName: 'Sarah Mitchell',
      partnerVerificationLevel: 'level2',
      scheduledAt: DateTime.now().add(const Duration(days: 4, hours: 2)),
      purpose: MeetingPurpose.coffee,
      location: 'Downtown Café, 42nd St',
      status: MeetingStatus.scheduled,
    ),
    MeetingEntity(
      id: 'm2',
      partnerId: 'c2',
      partnerName: 'James Carter',
      partnerVerificationLevel: 'level1',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
      purpose: MeetingPurpose.business,
      location: 'City Business Center',
      status: MeetingStatus.enRoute,
    ),
    MeetingEntity(
      id: 'm3',
      partnerId: 'c3',
      partnerName: 'Emily Torres',
      partnerVerificationLevel: 'level2',
      scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
      purpose: MeetingPurpose.property,
      location: 'Maple Street Listing',
      status: MeetingStatus.completed,
    ),
    MeetingEntity(
      id: 'm4',
      partnerId: 'c1',
      partnerName: 'Sarah Mitchell',
      partnerVerificationLevel: 'level2',
      scheduledAt: DateTime.now().subtract(const Duration(days: 10)),
      purpose: MeetingPurpose.coffee,
      location: 'Downtown Café, 42nd St',
      status: MeetingStatus.completed,
    ),
  ];

  static MeetingEntity byId(String id) => all.firstWhere(
        (m) => m.id == id,
        orElse: () => all.first,
      );
}
