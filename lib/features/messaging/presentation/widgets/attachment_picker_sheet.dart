import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_constants.dart';
import '../../domain/entities/message_entity.dart';

/// Result returned from [showAttachmentPickerSheet].
class AttachmentPickResult {
  final File file;
  final MessageType attachmentType;
  final String fileName;
  final int fileSize;
  final String? mimeType;

  const AttachmentPickResult({
    required this.file,
    required this.attachmentType,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
  });
}

/// Shows the bottom sheet and returns the picked file, or null on cancel/error.
Future<AttachmentPickResult?> showAttachmentPickerSheet(
    BuildContext context) async {
  return showModalBottomSheet<AttachmentPickResult>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AttachmentPickerSheet(),
  );
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close,
                      color: AppColors.textSecondary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PickOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _pickImage(context, ImageSource.gallery),
                ),
                _PickOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: AppColors.primary,
                  onTap: () => _pickImage(context, ImageSource.camera),
                ),
                _PickOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: AppColors.blue,
                  onTap: () => _pickDocument(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final navigator = Navigator.of(context);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xFile == null) {
        navigator.pop(null);
        return;
      }

      final file = File(xFile.path);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxImageSizeBytes) {
        if (context.mounted) {
          _showSizeError(context, 'Images must be smaller than 10 MB');
        }
        navigator.pop(null);
        return;
      }

      final ext = xFile.name.split('.').last.toLowerCase();
      if (!AppConstants.allowedImageExtensions.contains(ext)) {
        if (context.mounted) {
          _showSizeError(context, 'Unsupported image format');
        }
        navigator.pop(null);
        return;
      }

      navigator.pop(AttachmentPickResult(
        file: file,
        attachmentType: MessageType.image,
        fileName: xFile.name,
        fileSize: fileSize,
        mimeType: 'image/$ext',
      ));
    } catch (_) {
      navigator.pop(null);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.allowedDocumentExtensions,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        navigator.pop(null);
        return;
      }

      final picked = result.files.first;
      if (picked.path == null) {
        navigator.pop(null);
        return;
      }

      final file = File(picked.path!);
      final fileSize = picked.size;

      if (fileSize > AppConstants.maxDocumentSizeBytes) {
        if (context.mounted) {
          _showSizeError(context, 'Documents must be smaller than 25 MB');
        }
        navigator.pop(null);
        return;
      }

      final ext = (picked.extension ?? '').toLowerCase();
      if (!AppConstants.allowedDocumentExtensions.contains(ext)) {
        if (context.mounted) {
          _showSizeError(context, 'Unsupported document type');
        }
        navigator.pop(null);
        return;
      }

      navigator.pop(AttachmentPickResult(
        file: file,
        attachmentType: MessageType.document,
        fileName: picked.name,
        fileSize: fileSize,
        mimeType: _mimeForExtension(ext),
      ));
    } catch (_) {
      navigator.pop(null);
    }
  }

  void _showSizeError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _mimeForExtension(String ext) {
    const map = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',
    };
    return map[ext];
  }
}

class _PickOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
