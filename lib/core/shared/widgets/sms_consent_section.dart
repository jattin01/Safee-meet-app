import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import 'app_snackbar.dart';

/// SMS opt-in block shown above every "Send OTP" button (sign-up and
/// sign-in), as required by the US/Canada toll-free SMS compliance review:
/// separate, unchecked-by-default consent checkboxes per message type, plus
/// the fee / frequency / HELP-STOP disclosure and links to Terms and
/// Privacy Policy — all visible *before* the first SMS is sent.
///
/// Purely presentational: the parent owns the three booleans and decides
/// what they gate (only [otpConsent] is required to send an OTP).
class SmsConsentSection extends StatefulWidget {
  final bool otpConsent;
  final bool alertsConsent;
  final bool marketingConsent;
  final ValueChanged<bool> onOtpConsentChanged;
  final ValueChanged<bool> onAlertsConsentChanged;
  final ValueChanged<bool> onMarketingConsentChanged;

  const SmsConsentSection({
    super.key,
    required this.otpConsent,
    required this.alertsConsent,
    required this.marketingConsent,
    required this.onOtpConsentChanged,
    required this.onAlertsConsentChanged,
    required this.onMarketingConsentChanged,
  });

  @override
  State<SmsConsentSection> createState() => _SmsConsentSectionState();
}

class _SmsConsentSectionState extends State<SmsConsentSection> {
  // Kept as fields (not created inline in build) so they can be disposed,
  // same pattern as the register page's Terms/Privacy recognizers.
  late final _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => _openUrl(AppConstants.termsOfServiceUrl);
  late final _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => _openUrl(AppConstants.privacyPolicyUrl);

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) AppSnackbar.info(context, 'Could not open link.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle =
        TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'I agree to receive SMS from SAFEE MEET for:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _ConsentCheckbox(
            value: widget.otpConsent,
            onChanged: widget.onOtpConsentChanged,
            text: 'One-time passcodes (OTP) for account security and verification',
            required: true,
          ),
          _ConsentCheckbox(
            value: widget.alertsConsent,
            onChanged: widget.onAlertsConsentChanged,
            text: 'Recurring SOS alerts, meeting reminders and account notifications',
          ),
          _ConsentCheckbox(
            value: widget.marketingConsent,
            onChanged: widget.onMarketingConsentChanged,
            text: 'Recurring offers and product updates',
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 11, color: AppColors.textTertiary, height: 1.5),
              children: [
                const TextSpan(
                  text: 'Message frequency may vary. Message and data rates '
                      'may apply. Reply HELP for help, Reply STOP to cancel. ',
                ),
                TextSpan(
                  text: 'Terms',
                  style: linkStyle,
                  recognizer: _termsRecognizer,
                ),
                const TextSpan(text: ' · '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: linkStyle,
                  recognizer: _privacyRecognizer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  final bool required;

  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.text,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: text),
                    if (required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
