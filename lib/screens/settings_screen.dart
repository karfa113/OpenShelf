import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final auth = context.watch<AuthProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text('Settings',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),

          _Section(title: 'Account', children: [
            _AccountIdentity(
              email: auth.user?.email ?? 'Signed in',
              name: auth.user?.displayName,
              photoUrl: auth.user?.photoURL,
            ),
            const Divider(color: AppColors.border, height: 24),
            _Row(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              subtitle: 'You can sign back in any time',
              destructive: true,
              onTap: () => _confirmSignOut(context),
            ),
          ]),

          const SizedBox(height: 8),
          _Section(title: 'Export', children: [
            if (!kIsWeb) ...[
              _Row(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Generate PDF',
                subtitle: 'Full library manual with cover & tables',
                onTap: () => _downloadPdf(context, lib),
              ),
              const Divider(color: AppColors.border, height: 24),
              _Row(
                icon: Icons.file_upload_outlined,
                label: 'Export JSON',
                subtitle: 'Share or save your library data',
                onTap: () => _exportJson(context, lib),
              ),
              const Divider(color: AppColors.border, height: 24),
              _Row(
                icon: Icons.file_download_outlined,
                label: 'Import JSON',
                subtitle: 'Restore from a previous export',
                onTap: () => _importJson(context, lib),
              ),
            ] else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'PDF export and file import/export are available on the mobile app.',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                ),
              ),
          ]),

          const SizedBox(height: 8),
          _Section(title: 'About', children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OpenShelf · v1.0',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('A personal reading tracker and TBR list.',
                      style: GoogleFonts.inter(
                          color: AppColors.textTertiary, fontSize: 13)),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign out?',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        content: Text(
          'Your library stays safe in the cloud and reloads when you sign back in.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign out',
                style: GoogleFonts.inter(
                    color: const Color(0xFFFFB4B4),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().signOut();
  }

  Future<void> _downloadPdf(BuildContext context, LibraryProvider lib) async {
    try {
      final bytes = await PdfService().generateLibraryManual(lib.all);
      final now = DateTime.now();
      final stamp = DateFormat('yyyy-MM-dd-HHmm').format(now);
      final filename = 'Library-Manual-$stamp.pdf';

      Directory? dir;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        if (Platform.isAndroid || Platform.isIOS) {
          await Share.shareXFiles([XFile(file.path)], text: 'Library Manual');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloaded to ${file.path}')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate PDF')));
      }
    }
  }

  Future<void> _exportJson(BuildContext context, LibraryProvider lib) async {
    final json = await lib.exportJsonString();
    final dir = await getTemporaryDirectory();
    final stamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/library-export-$stamp.json');
    await file.writeAsString(json);
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to ${file.path}')));
      }
    }
  }

  Future<void> _importJson(BuildContext context, LibraryProvider lib) async {
    final picked = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null) return;
    final raw = await File(path).readAsString();
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Replace library?',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
        content: Text('This will replace your current library.',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Import',
                  style: GoogleFonts.inter(color: AppColors.accent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await lib.importFromJsonString(raw, replace: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import successful')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      }
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMid),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  const _Row(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap,
      this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final iconColor =
        destructive ? const Color(0xFFFFB4B4) : AppColors.accent;
    final labelColor =
        destructive ? const Color(0xFFFFB4B4) : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.spaceGrotesk(
                          color: labelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AccountIdentity extends StatelessWidget {
  final String email;
  final String? name;
  final String? photoUrl;
  const _AccountIdentity({
    required this.email,
    this.name,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _Avatar(photoUrl: photoUrl, email: email),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name == null || name!.isEmpty) ? 'Signed in' : name!,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String email;
  const _Avatar({required this.photoUrl, required this.email});

  @override
  Widget build(BuildContext context) {
    final initial = (email.isNotEmpty ? email[0] : '?').toUpperCase();
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
    );
  }
}


