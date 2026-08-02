import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/app_list_card.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/primary_button.dart';

// PROTOTYPE MODE: field validation and the network call are disabled —
// this just walks through the UI and pops the page. Re-connect it to the
// /auth/password endpoint and restore validation before shipping.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasLength => _newCtrl.text.length >= AppConstants.passwordMinLength;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newCtrl.text);
  bool get _hasMixedCase => RegExp(r'[A-Z]').hasMatch(_newCtrl.text) && RegExp(r'[a-z]').hasMatch(_newCtrl.text);
  bool get _matches => _newCtrl.text.isNotEmpty && _newCtrl.text == _confirmCtrl.text;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
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
            const DarkScreenHeader(title: 'Change Password'),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, context.bottomSafePadding(32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppListCard(children: [
                    _PasswordRow(
                      label: 'Current Password',
                      controller: _currentCtrl,
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    _PasswordRow(
                      label: 'New Password',
                      controller: _newCtrl,
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      onChanged: (_) => setState(() {}),
                    ),
                    _PasswordRow(
                      label: 'Confirm Password',
                      controller: _confirmCtrl,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      onChanged: (_) => setState(() {}),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password requirements',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        _Requirement(met: _hasLength, text: 'At least ${AppConstants.passwordMinLength} characters'),
                        _Requirement(met: _hasNumber, text: 'Contains a number'),
                        _Requirement(met: _hasMixedCase, text: 'Contains uppercase & lowercase'),
                        _Requirement(met: _matches, text: 'Matches confirmation'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Update Password', onPressed: () => context.pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;

  const _PasswordRow({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
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
            child: Icon(Icons.lock_outline, color: AppColors.textTertiary, size: 19),
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
                  obscureText: obscure,
                  onChanged: onChanged,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textTertiary,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final bool met;
  final String text;
  const _Requirement({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? AppColors.success : AppColors.textTertiary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: met ? AppColors.success : AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}
