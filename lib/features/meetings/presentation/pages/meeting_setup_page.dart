import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../domain/entities/meeting_entity.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no
// MeetingsBloc wiring or backend connectivity. Re-connect it to
// MeetingsBloc (MeetingScheduleRequested) before shipping.
class MeetingSetupPage extends StatefulWidget {
  final String? partnerId;
  const MeetingSetupPage({super.key, this.partnerId});

  @override
  State<MeetingSetupPage> createState() => _MeetingSetupPageState();
}

class _MeetingSetupPageState extends State<MeetingSetupPage> {
  final _locationCtrl = TextEditingController(text: 'Downtown Café, 42nd St, New York');
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime(2026, 6, 14);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  MeetingPurpose _selectedPurpose = MeetingPurpose.coffee;

  static const _purposes = [
    (MeetingPurpose.coffee, '☕'),
    (MeetingPurpose.marketplace, '🛍️'),
    (MeetingPurpose.property, '🏠'),
    (MeetingPurpose.business, '💼'),
    (MeetingPurpose.freelance, '💻'),
    (MeetingPurpose.social, '👥'),
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DarkScreenHeader(title: 'Create Meeting'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('MEETING WITH'),
                  const SizedBox(height: 10),
                  const _PartnerCard(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _Label('DATE')),
                      const SizedBox(width: 12),
                      Expanded(child: _Label('TIME')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat('MMM d, y').format(_selectedDate),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerField(
                          icon: Icons.access_time,
                          label: _selectedTime.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Label('MEETING PURPOSE'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: _purposes.map((p) {
                      final active = p.$1 == _selectedPurpose;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPurpose = p.$1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: active ? AppColors.warning.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? AppColors.warning : AppColors.border,
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.$2, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 6),
                              Text(
                                p.$1.label,
                                style: GoogleFonts.inter(
                                  color: active ? AppColors.warning : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  FieldInput(
                    label: 'Location',
                    hint: 'Enter address or place name',
                    controller: _locationCtrl,
                    prefixIcon: Icons.location_on_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _MapPreview(label: _locationCtrl.text),
                  const SizedBox(height: 20),
                  _Label('NOTES (OPTIONAL)'),
                  const SizedBox(height: 10),
                  _NotesField(controller: _notesCtrl),
                  const SizedBox(height: 20),
                  const _SafetyBanner(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create Safe Meeting',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFFDCEBFF), shape: BoxShape.circle),
            child: const Center(child: Text('🐱', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sarah Mitchell',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.blue, size: 13),
                    const SizedBox(width: 4),
                    Text('Level 2 Verified', style: TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Text('Change', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final String label;
  const _MapPreview({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List.generate(
                6,
                (i) => Container(
                  width: 64,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkBg.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📍', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 4,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Add any notes or instructions…',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.mic, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Safety Features Active',
                style: GoogleFonts.inter(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your trusted contacts will be notified when this meeting starts. '
            'Live location sharing and SOS are pre-enabled.',
            style: TextStyle(color: AppColors.success, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
