import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../domain/entities/emergency_share_entity.dart';
import '../bloc/emergency_share_bloc.dart';

class EmergencySharePage extends StatefulWidget {
  final String meetingId;
  const EmergencySharePage({super.key, required this.meetingId});

  @override
  State<EmergencySharePage> createState() => _EmergencySharePageState();
}

class _EmergencySharePageState extends State<EmergencySharePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<EmergencyShareBloc>()
          .add(EmergencyShareRequested(widget.meetingId));
    });
  }

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<EmergencyShareBloc>();
    final done = bloc.stream.firstWhere(
        (s) => s is EmergencyShareLoaded || s is EmergencyShareError);
    bloc.add(EmergencyShareRequested(widget.meetingId));
    return done;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Emergency Share',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<EmergencyShareBloc, EmergencyShareState>(
        builder: (context, state) {
          if (state is EmergencyShareLoading ||
              state is EmergencyShareInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EmergencyShareError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<EmergencyShareBloc>()
                          .add(EmergencyShareRequested(widget.meetingId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! EmergencyShareLoaded) {
            return const SizedBox.shrink();
          }

          final data = state.data;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _refresh(context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, context.bottomSafePadding(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MeetingCard(meeting: data.meeting),
                  const SizedBox(height: 16),
                  _UserCard(title: 'Host', user: data.host, icon: Icons.person),
                  const SizedBox(height: 16),
                  _UserCard(
                      title: 'Guest',
                      user: data.guest,
                      icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _EmergencyContactsCard(contacts: data.emergencyContacts),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final EmergencyShareMeetingEntity meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Meeting Details'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  meeting.reference.isNotEmpty ? meeting.reference : meeting.id,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meeting.status,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.calendar_today,
              label: '${meeting.meetingDate} · ${meeting.meetingTime}'),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.location_on_outlined,
              label: meeting.location.isNotEmpty
                  ? meeting.location
                  : 'Location unavailable'),
          if (meeting.latitude != null && meeting.longitude != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.gps_fixed,
              label:
                  '${meeting.latitude!.toStringAsFixed(4)}° N, ${meeting.longitude!.toStringAsFixed(4)}° E',
            ),
          ],
          if (meeting.purpose != null && meeting.purpose!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.notes, label: meeting.purpose!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final String title;
  final EmergencyShareUserEntity user;
  final IconData icon;
  const _UserCard(
      {required this.title, required this.user, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.phone ?? 'Phone not available',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactsCard extends StatelessWidget {
  final List<EmergencyShareContactEntity> contacts;
  const _EmergencyContactsCard({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              const _SectionTitle('Emergency Contacts'),
            ],
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty)
            Text(
              'No emergency contacts on file.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            ...contacts.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.fullName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (c.relationship != null &&
                                  c.relationship!.isNotEmpty)
                                Text(
                                  c.relationship!,
                                  style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          c.phoneNumber ?? 'No phone',
                          style: TextStyle(
                            color: c.phoneNumber != null
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
