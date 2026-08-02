import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

/// Standard "you're offline" state for any API-driven screen — swap in for
/// whatever generic error widget the screen would otherwise show once the
/// failure is confirmed to be a [NetworkFailure] (see `dio_failure_mapper`),
/// so a dropped connection reads as "no internet", not a server/token error.
class NoInternetView extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const NoInternetView({
    super.key,
    required this.onRetry,
    this.message =
        'Please check your internet connection and try again.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textTertiary.withOpacity(0.1),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: AppColors.textTertiary, size: 38),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
