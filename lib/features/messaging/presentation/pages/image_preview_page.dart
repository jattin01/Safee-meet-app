import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/config/app_colors.dart';

/// Full-screen image viewer with pinch-zoom and save-to-Downloads.
/// Pass either [imageUrl] (remote) or [localPath] (local file before upload).
/// [mimeType] is used to set the correct MIME on the downloaded file.
class ImagePreviewPage extends StatefulWidget {
  final String? imageUrl;
  final String? localPath;
  final String? heroTag;
  final String? mimeType;

  const ImagePreviewPage({
    super.key,
    this.imageUrl,
    this.localPath,
    this.heroTag,
    this.mimeType,
  }) : assert(imageUrl != null || localPath != null,
            'Either imageUrl or localPath must be provided');

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  // Method channel pointing at the DownloadManager bridge in MainActivity.kt
  static const _channel =
      MethodChannel('solutionbowl.com.safee_meet/downloader');

  bool _isDownloading = false;

  Future<void> _download() async {
    if (_isDownloading || widget.imageUrl == null) return;

    // On Android < 10 (API ≤ 28) DownloadManager needs WRITE_EXTERNAL_STORAGE.
    // The permission is declared in the manifest with maxSdkVersion="28", so
    // permission_handler returns "denied" on API ≥ 29 even though no permission
    // is actually required there. Only abort when the user permanently denied it
    // on an older device.
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        _show('Storage permission permanently denied. Enable it in app settings.');
        await openAppSettings();
        return;
      }
    }

    setState(() => _isDownloading = true);

    try {
      final ext = _extFromMime(widget.mimeType);
      final fileName = 'SafeeMeet_${DateTime.now().millisecondsSinceEpoch}$ext';

      await _channel.invokeMethod<int>('downloadFile', {
        'url': widget.imageUrl!,
        'fileName': fileName,
        'mimeType': widget.mimeType ?? 'image/jpeg',
      });

      _show('Saved Successfully');
    } on PlatformException catch (e) {
      _show('Download failed: ${e.message}');
    } catch (_) {
      _show('Download failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _extFromMime(String? mime) {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg';
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.darkBg2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Only show download button for remote images
          if (widget.imageUrl != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_rounded,
                        color: Colors.white, size: 20),
              ),
              tooltip: 'Save to Downloads',
              onPressed: _isDownloading ? null : _download,
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.localPath != null) {
      final tag = widget.heroTag ?? widget.localPath!;
      return Hero(
        tag: tag,
        child: Image.file(
          File(widget.localPath!),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const _ErrorPlaceholder(),
        ),
      );
    }

    final tag = widget.heroTag ?? widget.imageUrl!;
    return Hero(
      tag: tag,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
        errorWidget: (_, __, ___) => const _ErrorPlaceholder(),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
        SizedBox(height: 12),
        Text(
          'Could not load image',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }
}
