import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../../member_search/domain/entities/member_entity.dart';
import '../../../member_search/presentation/pages/member_search_page.dart';
import '../../domain/entities/meeting_entity.dart';
import '../bloc/meetings_bloc.dart';
import 'location_picker_page.dart';

class MeetingSetupPage extends StatelessWidget {
  final String? partnerId;
  final MemberEntity? partner;
  const MeetingSetupPage({super.key, this.partnerId, this.partner});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MeetingsBloc>(),
      child: _MeetingSetupView(partnerId: partnerId, partner: partner),
    );
  }
}

class _MeetingSetupView extends StatefulWidget {
  final String? partnerId;
  final MemberEntity? partner;
  const _MeetingSetupView({this.partnerId, this.partner});

  @override
  State<_MeetingSetupView> createState() => _MeetingSetupViewState();
}

class _MeetingSetupViewState extends State<_MeetingSetupView> {
  final _locationCtrl = TextEditingController();
  final _buildingNameCtrl = TextEditingController();
  final _floorFlatCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  MeetingPurpose _selectedPurpose = MeetingPurpose.coffee;
  late MemberEntity? _selectedPartner = widget.partner;
  double? _pickedLatitude;
  double? _pickedLongitude;

  static const _purposes = [
    (MeetingPurpose.coffee, '☕'),
    (MeetingPurpose.marketplace, '🛍️'),
    (MeetingPurpose.property, '🏠'),
    (MeetingPurpose.business, '💼'),
    (MeetingPurpose.freelance, '💻'),
    (MeetingPurpose.social, '👥'),
  ];

  String? get _partnerId => _selectedPartner?.id ?? widget.partnerId;

  Future<void> _pickPartner() async {
    final selected = await Navigator.of(context).push<MemberEntity>(
      MaterialPageRoute(builder: (_) => const MemberSearchPage(pickerMode: true)),
    );
    if (selected != null) setState(() => _selectedPartner = selected);
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (picked == null) return;
    setState(() {
      _locationCtrl.text = picked.address;
      _pickedLatitude = picked.latitude;
      _pickedLongitude = picked.longitude;
    });
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _buildingNameCtrl.dispose();
    _floorFlatCtrl.dispose();
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
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
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
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submit() {
    final partnerId = _partnerId;
    final baseLocation = _locationCtrl.text.trim();

    if (partnerId == null || partnerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select who you\'re meeting with first.')),
      );
      return;
    }
    if (baseLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required.')),
      );
      return;
    }

    // Prepend flat/floor and building details, if given, to the map/typed
    // address so the backend still just receives one formatted string.
    final location = [
      _floorFlatCtrl.text.trim(),
      _buildingNameCtrl.text.trim(),
      baseLocation,
    ].where((s) => s.isNotEmpty).join(', ');

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    context.read<MeetingsBloc>().add(
          MeetingScheduleRequested(
            partnerId: partnerId,
            scheduledAt: scheduledAt,
            purpose: _selectedPurpose,
            location: location,
            latitude: _pickedLatitude,
            longitude: _pickedLongitude,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocConsumer<MeetingsBloc, MeetingsState>(
        listener: (context, state) {
          if (state is MeetingScheduled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meeting created successfully.')),
            );
            context.pop();
          } else if (state is MeetingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is MeetingsLoading;

          return SingleChildScrollView(
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
                      _PartnerCard(
                        partner: _selectedPartner,
                        partnerId: widget.partnerId,
                        onTap: _pickPartner,
                      ),
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
                      GestureDetector(
                        onTap: _pickLocationOnMap,
                        child: AbsorbPointer(
                          child: FieldInput(
                            label: 'Location',
                            hint: 'Tap to select location on map',
                            controller: _locationCtrl,
                            readOnly: true,
                            suffixWidget: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FieldInput(
                        label: 'Building Name (Optional)',
                        hint: 'e.g. Sunrise Apartments',
                        controller: _buildingNameCtrl,
                        prefixIcon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 14),
                      FieldInput(
                        label: 'Floor / Flat Number (Optional)',
                        hint: 'e.g. 4th Floor, 402',
                        controller: _floorFlatCtrl,
                        prefixIcon: Icons.door_front_door_outlined,
                      ),
                      const SizedBox(height: 20),
                      _Label('NOTES (OPTIONAL)'),
                      const SizedBox(height: 10),
                      _NotesField(controller: _notesCtrl),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: isSubmitting ? 'Creating…' : 'Create Safe Meeting',
                        onPressed: isSubmitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
  final MemberEntity? partner;
  final String? partnerId;
  final VoidCallback onTap;
  const _PartnerCard({this.partner, this.partnerId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPartner = partner != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasPartner ? AppColors.border : AppColors.warning),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFDCEBFF), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  hasPartner ? partner!.initials : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPartner ? partner!.name : (partnerId ?? 'No member selected'),
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (hasPartner) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.verified, color: AppColors.blue, size: 13),
                        const SizedBox(width: 4),
                        Text(partner!.verificationLevel,
                            style: TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              hasPartner ? 'Change' : 'Select',
              style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
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
      child: TextField(
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
    );
  }
}

