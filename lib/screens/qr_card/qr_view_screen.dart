import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/business_card.dart';
import '../../utils/app_constants.dart';

class QRViewScreen extends StatelessWidget {
  final BusinessCard card;

  const QRViewScreen({super.key, required this.card});

  String _buildVCardString() {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    buffer.writeln('FN:${card.name}');

    final nameParts = card.name.trim().split(' ');
    final lastName = nameParts.length > 1 ? nameParts.last : '';
    final firstName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join(' ')
        : nameParts.first;
    buffer.writeln('N:$lastName;$firstName;;;');

    if (card.company != null && card.company!.isNotEmpty) {
      buffer.writeln('ORG:${card.company}');
    }
    if (card.jobTitle != null && card.jobTitle!.isNotEmpty) {
      buffer.writeln('TITLE:${card.jobTitle}');
    }
    if (card.phone != null && card.phone!.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL:${card.phone}');
    }
    if (card.email != null && card.email!.isNotEmpty) {
      buffer.writeln('EMAIL:${card.email}');
    }
    if (card.website != null && card.website!.isNotEmpty) {
      buffer.writeln('URL:${card.website}');
    }

    buffer.write('END:VCARD');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrData = _buildVCardString();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(card.name),
        backgroundColor: ModuleColors.qrCardLight,
        foregroundColor: ModuleColors.qrCard,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _buildInfoCard(theme),
            const SizedBox(height: AppSpacing.lg),
            _buildQRCard(context, qrData),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: ModuleColors.qrCardLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: ModuleColors.qrCard, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Share this QR code for others to scan and save your contact details automatically.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ModuleColors.qrCard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ModuleColors.qrCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.badge_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (card.jobTitle != null)
                        Text(card.jobTitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: ModuleColors.qrCard,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            if (_hasAnyContact()) ...[
              const Divider(height: 24),
              if (card.company != null && card.company!.isNotEmpty)
                _infoRow(Icons.business_outlined, card.company!, theme),
              if (card.email != null && card.email!.isNotEmpty)
                _infoRow(Icons.email_outlined, card.email!, theme),
              if (card.phone != null && card.phone!.isNotEmpty)
                _infoRow(Icons.phone_outlined, card.phone!, theme),
              if (card.website != null && card.website!.isNotEmpty)
                _infoRow(Icons.language_outlined, card.website!, theme),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasAnyContact() =>
      (card.company?.isNotEmpty ?? false) ||
      (card.email?.isNotEmpty ?? false) ||
      (card.phone?.isNotEmpty ?? false) ||
      (card.website?.isNotEmpty ?? false);

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard(BuildContext context, String qrData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              'QR Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: ModuleColors.qrCardLight,
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                embeddedImage: null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Point a camera at this code to scan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
