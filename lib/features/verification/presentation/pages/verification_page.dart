import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/info_banner.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../domain/entities/verification_entity.dart';
import '../bloc/verification_bloc.dart';

const _nationalIdCountry = 'india';

enum _Step { uploadId, selfie, processing, complete }

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  _Step _step = _Step.uploadId;
  File? _idFront;
  File? _idBack;
  File? _selfie;
  VerificationEntity? _progress;
  String? _submittedStatus;
  final _picker = ImagePicker();
  final _nationalIdNumberController = TextEditingController();

  static const _stepLabels = ['Upload ID', 'Selfie', 'Processing', 'Complete'];

  int get _stepIndex => _step.index;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<VerificationBloc>()
          .add(const VerificationProgressRequested());
    });
  }

  @override
  void dispose() {
    _nationalIdNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, _ImageType type) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (xFile == null || !mounted) return;
    final file = File(xFile.path);
    setState(() {
      switch (type) {
        case _ImageType.front:
          _idFront = file;
        case _ImageType.back:
          _idBack = file;
        case _ImageType.selfie:
          _selfie = file;
      }
    });
  }

  void _syncProgress(VerificationEntity progress) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _step = switch (progress.currentStep) {
        VerificationStep.selfie => _Step.selfie,
        VerificationStep.processing => _Step.processing,
        VerificationStep.complete => _Step.complete,
        VerificationStep.uploadId => _Step.uploadId,
      };
    });
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _submitIdDocuments() {
    if (_idFront == null || _idBack == null) {
      _showMessage('Please upload both sides of your ID before continuing.',
          error: true);
      return;
    }
    if (_nationalIdNumberController.text.trim().isEmpty) {
      _showMessage('Please enter your National ID number before continuing.',
          error: true);
      return;
    }

    setState(() => _step = _Step.selfie);
  }

  void _submitSelfie() {
    if (_idFront == null || _idBack == null) {
      _showMessage('Please upload both sides of your ID before continuing.',
          error: true);
      setState(() => _step = _Step.uploadId);
      return;
    }
    if (_selfie == null) {
      _showMessage('Please capture a selfie before submitting.', error: true);
      return;
    }

    context.read<VerificationBloc>().add(
          VerificationSubmitted(
            faceIdImage: _selfie!,
            nationalIdFrontImage: _idFront!,
            nationalIdBackImage: _idBack!,
            nationalIdNumber: _nationalIdNumberController.text.trim(),
            nationalIdCountry: _nationalIdCountry,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        if (state is VerificationProgressLoaded) {
          _syncProgress(state.progress);
        }

        if (state is VerificationUploadSuccess) {
          _showMessage(state.message);
          setState(() {
            _submittedStatus = state.data.status;
            _step = _Step.processing;
          });
        }

        if (state is VerificationError) {
          _showMessage(state.message, error: true);
        }
      },
      builder: (context, state) {
        final initialLoad = state is VerificationLoading && _progress == null;
        final isUploading = state is VerificationUploading;

        if (initialLoad) {
          return const Scaffold(
            backgroundColor: AppColors.lightBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.lightBg,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarkScreenHeader(
                  title: 'Identity Verification',
                  titleFontSize: 21,
                  childGap: 24,
                  child: _StepCircleRow(
                      activeIndex: _stepIndex, labels: _stepLabels),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: _buildStep(context, isUploading: isUploading),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, {required bool isUploading}) {
    switch (_step) {
      case _Step.uploadId:
        return _UploadIdStep(
          front: _idFront,
          back: _idBack,
          hasServerFront: _progress?.hasIdFront ?? false,
          hasServerBack: _progress?.hasIdBack ?? false,
          rejectionReason: _progress?.status == 'rejected'
              ? _progress?.rejectionReason
              : null,
          isSubmitting: false,
          nationalIdNumberController: _nationalIdNumberController,
          onPickFront: () => _pickImage(ImageSource.gallery, _ImageType.front),
          onPickBack: () => _pickImage(ImageSource.gallery, _ImageType.back),
          onContinue: _submitIdDocuments,
        );
      case _Step.selfie:
        return _SelfieStep(
          selfie: _selfie,
          hasServerSelfie: _progress?.hasSelfie ?? false,
          isSubmitting: isUploading,
          onPickSelfie: () => _pickImage(ImageSource.camera, _ImageType.selfie),
          onSubmit: _submitSelfie,
        );
      case _Step.processing:
        return _ProcessingStep(
          status: _submittedStatus ?? _progress?.status ?? 'pending',
          onRefresh: () => context
              .read<VerificationBloc>()
              .add(const VerificationProgressRequested()),
          onViewStatus: () => context.go(AppRoutes.verificationStatus),
        );
      case _Step.complete:
        return _CompleteStep(
          onViewStatus: () => context.go(AppRoutes.verificationStatus),
        );
    }
  }
}

enum _ImageType { front, back, selfie }

class _StepCircleRow extends StatelessWidget {
  final int activeIndex;
  final List<String> labels;

  const _StepCircleRow({required this.activeIndex, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isLast = i == labels.length - 1;
        return <Widget>[
          _StepCircle(
            number: i + 1,
            state: i < activeIndex
                ? _CircleState.done
                : i == activeIndex
                    ? _CircleState.active
                    : _CircleState.pending,
            label: labels[i],
          ),
          if (!isLast)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < activeIndex
                    ? AppColors.success
                    : Colors.white.withOpacity(0.15),
              ),
            ),
        ];
      }).expand((w) => w).toList(),
    );
  }
}

enum _CircleState { done, active, pending }

class _StepCircle extends StatelessWidget {
  final int number;
  final _CircleState state;
  final String label;

  const _StepCircle(
      {required this.number, required this.state, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (state) {
      _CircleState.done => AppColors.success,
      _CircleState.active => AppColors.primary,
      _CircleState.pending => Colors.white.withOpacity(0.08),
    };
    final Color textColor =
        state == _CircleState.pending ? AppColors.textTertiary : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: state == _CircleState.done
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: state == _CircleState.pending
                ? AppColors.textTertiary
                : Colors.white,
            fontSize: 11,
            fontWeight: state == _CircleState.active
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _StepIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _UploadIdStep extends StatelessWidget {
  final File? front;
  final File? back;
  final bool hasServerFront;
  final bool hasServerBack;
  final String? rejectionReason;
  final bool isSubmitting;
  final TextEditingController nationalIdNumberController;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;
  final VoidCallback onContinue;

  const _UploadIdStep({
    required this.front,
    required this.back,
    required this.hasServerFront,
    required this.hasServerBack,
    required this.rejectionReason,
    required this.isSubmitting,
    required this.nationalIdNumberController,
    required this.onPickFront,
    required this.onPickBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: _StepIcon(
                icon: Icons.description_outlined, color: AppColors.blue)),
        const SizedBox(height: 20),
        Text(
          'Upload Government ID',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          "Driver's license, passport, or national ID",
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        if (rejectionReason != null) ...[
          const SizedBox(height: 20),
          InfoBanner(
            emoji: '⚠️',
            text: 'Previous submission was rejected: $rejectionReason',
            color: AppColors.warning,
          ),
        ],
        const SizedBox(height: 28),
        _UploadRow(
          icon: Icons.credit_card,
          title: 'ID Front Side',
          file: front,
          uploadedOnServer: hasServerFront,
          onTap: onPickFront,
        ),
        const SizedBox(height: 14),
        _UploadRow(
          icon: Icons.badge_outlined,
          title: 'ID Back Side',
          file: back,
          uploadedOnServer: hasServerBack,
          onTap: onPickBack,
        ),
        const SizedBox(height: 20),
        FieldInput(
          label: 'National ID Number',
          hint: 'Enter your National ID number',
          controller: nationalIdNumberController,
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),
        const InfoBanner(
          emoji: '🔒',
          text:
              'Your ID is stored securely and shared only for verification review',
          color: AppColors.blue,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: isSubmitting ? 'Uploading...' : 'Continue to Selfie',
          onPressed: isSubmitting ? null : onContinue,
        ),
      ],
    );
  }
}

class _SelfieStep extends StatelessWidget {
  final File? selfie;
  final bool hasServerSelfie;
  final bool isSubmitting;
  final VoidCallback onPickSelfie;
  final VoidCallback onSubmit;

  const _SelfieStep({
    required this.selfie,
    required this.hasServerSelfie,
    required this.isSubmitting,
    required this.onPickSelfie,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: _StepIcon(icon: Icons.camera_alt, color: AppColors.primary)),
        const SizedBox(height: 20),
        Text(
          'Selfie Verification',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Take a selfie to match with your ID photo',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.darkBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: selfie != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(selfie!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      cacheWidth: 800),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: CustomPaint(
                        painter: _DashedRRectPainter(color: AppColors.primary),
                        child: SizedBox(
                          width: 180,
                          height: 240,
                          child: Icon(Icons.person_outline,
                              color: Colors.white.withOpacity(0.3), size: 56),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      child: Text(
                        hasServerSelfie
                            ? 'Selfie already uploaded'
                            : 'Position your face in the frame',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        _UploadRow(
          icon: Icons.camera_alt_outlined,
          title: 'Take Selfie',
          file: selfie,
          uploadedOnServer: hasServerSelfie,
          onTap: onPickSelfie,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: isSubmitting ? 'Submitting...' : 'Submit for Verification',
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  const _DashedRRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dash = 6.0, gap = 5.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProcessingStep extends StatelessWidget {
  final String status;
  final VoidCallback onRefresh;
  final VoidCallback onViewStatus;

  const _ProcessingStep({
    required this.status,
    required this.onRefresh,
    required this.onViewStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isManualReview = status == 'manual_review';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child:
                _StepIcon(icon: Icons.access_time, color: AppColors.success)),
        const SizedBox(height: 20),
        Text(
          isManualReview ? 'Manual Review' : 'Processing',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          isManualReview
              ? 'Your verification needs an extra review by the SAFEE team'
              : 'Your verification is under review right now',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 28),
        const _ProcessingRow(
          icon: Icons.check_circle,
          color: AppColors.success,
          title: 'ID Received',
          subtitle: 'Front and back images uploaded',
          done: true,
        ),
        const _ProcessingRow(
          icon: Icons.check_circle,
          color: AppColors.success,
          title: 'Selfie Received',
          subtitle: 'Selfie submitted for review',
          done: true,
        ),
        _ProcessingRow(
          icon: isManualReview ? Icons.manage_search : Icons.access_time,
          color: isManualReview ? AppColors.warning : AppColors.primary,
          title: isManualReview ? 'Manual Review' : 'Review In Progress',
          subtitle: isManualReview
              ? 'Team is checking your submission'
              : 'Verification team is reviewing your details',
          done: false,
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'View Status', onPressed: onViewStatus),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRefresh,
          child: const Text('Refresh Progress'),
        ),
      ],
    );
  }
}

class _CompleteStep extends StatelessWidget {
  final VoidCallback onViewStatus;
  const _CompleteStep({required this.onViewStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: _StepIcon(icon: Icons.verified, color: AppColors.success)),
        const SizedBox(height: 20),
        Text(
          'Verification Complete',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your identity has been approved successfully',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        const InfoBanner(
          emoji: '✅',
          text: 'Your Level 1 verification badge is now active',
          color: AppColors.success,
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'View Status', onPressed: onViewStatus),
      ],
    );
  }
}

class _ProcessingRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool done;

  const _ProcessingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (done) Icon(Icons.check_circle, color: color, size: 18),
        ],
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final File? file;
  final bool uploadedOnServer;
  final VoidCallback onTap;

  const _UploadRow({
    required this.icon,
    required this.title,
    required this.file,
    required this.uploadedOnServer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = file != null || uploadedOnServer;
    final subtitle = file != null
        ? 'New photo selected'
        : uploadedOnServer
            ? 'Already uploaded, tap to replace'
            : 'Tap to upload or take photo';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.success : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.cardBg, shape: BoxShape.circle),
              child: Icon(
                selected ? Icons.check : icon,
                color: selected ? AppColors.success : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_outlined,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
