import 'package:flutter/material.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/gradient_header.dart';

class PolicyPage extends StatelessWidget {
  final String type; // 'privacy' | 'terms'
  const PolicyPage({super.key, required this.type});

  bool get isPrivacy => type == 'privacy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        children: [
          GradientHeader(
            title: isPrivacy ? 'Privacy Policy' : 'Terms of Service',
            subtitle: isPrivacy ? 'Last updated: January 2025' : 'Effective: January 2025',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                isPrivacy ? _privacyContent : _termsContent,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.8,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _privacyContent = '''
PRIVACY POLICY

1. INFORMATION WE COLLECT
We collect information you provide directly to us, such as when you create an account, complete identity verification, schedule meetings, or contact us for support.

Personal Information: name, email address, phone number, profile photo, government ID (for verification), biometric data (face match only).

Usage Information: how you interact with the app, meeting schedules, GPS location data when location sharing is enabled, device information.

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
- Provide, maintain, and improve our services
- Verify your identity for safety purposes
- Enable you to connect with other members
- Send safety notifications and SOS alerts
- Comply with legal obligations

3. INFORMATION SHARING
We do not sell your personal information. We may share information with:
- Other users (only what you choose to make public)
- Emergency contacts when SOS is activated
- Service providers who assist in our operations
- Law enforcement when required by law

4. DATA SECURITY
We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. YOUR RIGHTS
You have the right to access, correct, or delete your personal information. Contact privacy@safeemeet.com to exercise these rights.

6. CONTACT US
For privacy-related questions: privacy@safeemeet.com
''';

  static const _termsContent = '''
TERMS OF SERVICE

1. ACCEPTANCE OF TERMS
By accessing or using SAFEE MEET, you agree to be bound by these Terms of Service and our Privacy Policy.

2. ELIGIBILITY
You must be at least 18 years old to use SAFEE MEET. By using the service, you represent that you meet this requirement.

3. ACCOUNT RESPONSIBILITIES
You are responsible for maintaining the security of your account and for all activities that occur under your account. You must provide accurate and complete information.

4. PROHIBITED CONDUCT
You agree not to:
- Provide false information during registration or verification
- Use the service for illegal activities
- Harass, abuse, or harm other users
- Attempt to bypass security measures
- Share your account credentials with others

5. IDENTITY VERIFICATION
You consent to identity verification processes including document review and biometric comparison. False documents will result in immediate account termination.

6. SAFETY FEATURES
SOS features are for genuine emergencies only. Abuse of emergency features may result in account suspension and potential legal liability.

7. SUBSCRIPTION AND PAYMENTS
Subscriptions automatically renew unless cancelled. Refunds are subject to our refund policy.

8. LIMITATION OF LIABILITY
SAFEE MEET is not liable for any indirect, incidental, or consequential damages arising from your use of the service.

9. CONTACT
For questions about these terms: legal@safeemeet.com
''';
}
