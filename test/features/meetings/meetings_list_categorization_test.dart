import 'package:flutter_test/flutter_test.dart';
import 'package:safee_meet/features/meetings/domain/entities/meeting_entity.dart';

void main() {
  group('Meeting Categorization Logic', () {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 5));
    final pastDate = now.subtract(const Duration(days: 5));

    MeetingEntity createMeeting({
      required String id,
      required MeetingStatus status,
      required DateTime scheduledAt,
      bool isHost = true,
    }) {
      return MeetingEntity(
        id: id,
        partnerId: 'partner1',
        partnerName: 'Partner Name',
        partnerVerificationLevel: 'level1',
        scheduledAt: scheduledAt,
        purpose: MeetingPurpose.coffee,
        location: 'Test Location',
        status: status,
        isHost: isHost,
      );
    }

    test('meetings with incidentReported status appear under Past tab and NOT Upcoming tab regardless of date', () {
      final meetings = [
        createMeeting(
          id: '1',
          status: MeetingStatus.incidentReported,
          scheduledAt: futureDate, // scheduled in the future!
        ),
        createMeeting(
          id: '2',
          status: MeetingStatus.incidentReported,
          scheduledAt: pastDate, // scheduled in the past!
        ),
        createMeeting(
          id: '3',
          status: MeetingStatus.scheduled,
          scheduledAt: futureDate,
        ),
        createMeeting(
          id: '4',
          status: MeetingStatus.completed,
          scheduledAt: pastDate,
        ),
      ];

      final upcoming = meetings
          .where((m) =>
              m.status == MeetingStatus.scheduled ||
              m.status == MeetingStatus.enRoute ||
              m.status == MeetingStatus.arrived ||
              (m.status == MeetingStatus.pendingApproval && m.isHost))
          .toList();

      final past = meetings
          .where((m) =>
              m.status == MeetingStatus.completed ||
              m.status == MeetingStatus.cancelled ||
              m.status == MeetingStatus.declined ||
              m.status == MeetingStatus.incidentReported)
          .toList();

      // Verify incidentReported meetings are NOT in upcoming
      expect(upcoming.any((m) => m.status == MeetingStatus.incidentReported), false);
      expect(upcoming.map((m) => m.id), contains('3'));
      expect(upcoming.length, 1);

      // Verify incidentReported meetings ARE in past
      expect(past.where((m) => m.status == MeetingStatus.incidentReported).length, 2);
      expect(past.map((m) => m.id), containsAll(['1', '2', '4']));
      expect(past.length, 3);
    });
  });
}
