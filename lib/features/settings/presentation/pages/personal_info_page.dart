import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/primary_button.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no API
// wiring or backend connectivity. Re-connect it to the profile endpoint
// before shipping.
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _nameCtrl = TextEditingController(text: 'Alex Johnson');
  final _emailCtrl = TextEditingController(text: 'alex.johnson@email.com');
  final _phoneCtrl = TextEditingController(text: '+1 (555) 123-4567');
  bool _editing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DarkScreenHeader(title: 'Personal Information'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.person, color: Colors.white70, size: 38),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Tap to change photo', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppListCard(
                    children: _editing
                        ? [
                            _EditableRow(
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                            ),
                            _EditableRow(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _EditableRow(
                              icon: Icons.phone_outlined,
                              label: 'Mobile Number',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                            ),
                          ]
                        : [
                            _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: _nameCtrl.text),
                            _InfoRow(icon: Icons.email_outlined, label: 'Email Address', value: _emailCtrl.text),
                            _InfoRow(icon: Icons.phone_outlined, label: 'Mobile Number', value: _phoneCtrl.text),
                          ],
                  ),
                  const SizedBox(height: 20),
                  AppListCard(header: 'ACCOUNT INFO', children: [
                    _PlainRow(label: 'SAFEE PIN', value: '#SM-7821'),
                    _PlainRow(label: 'Member Since', value: 'May 2024'),
                    _PlainRow(label: 'Account Status', value: 'Active', valueColor: AppColors.success, valueIcon: Icons.check),
                  ]),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _editing ? 'Save Changes' : 'Edit Information',
                    onPressed: () => setState(() => _editing = !_editing),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _EditableRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Icon(icon, color: AppColors.textTertiary, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  inputFormatters: inputFormatters,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? valueIcon;

  const _PlainRow({required this.label, required this.value, this.valueColor, this.valueIcon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (valueIcon != null) ...[
                const SizedBox(width: 4),
                Icon(valueIcon, color: valueColor, size: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
