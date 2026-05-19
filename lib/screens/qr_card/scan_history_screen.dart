// ============================================================
//  screens/qr_card/scan_history_screen.dart  –  Scan History
// ============================================================
//
//  Shows all QR codes the user has previously scanned.
//  Each entry shows:
//  • The scanned text (truncated if long)
//  • When it was scanned (relative time)
//  • A "Copy" button to copy text to clipboard
//  • Swipe-to-delete (Dismissible widget)
//
//  Also contains a FAB to open the QR scanner camera.
//  This is where scanning starts, and results are shown here.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';         // For Clipboard
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/scan_history.dart';
import '../../providers/business_card_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import 'qr_scanner_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessCardProvider>().loadScanHistory();
    });
  }

  // ── Open scanner camera ────────────────────────────────────
  Future<void> _openScanner() async {
    // Navigator.push returns a value if the screen pops with one
    // QRScannerScreen calls Navigator.pop(context, scannedText)
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    // After returning, reload history to show the new scan
    if (result != null && mounted) {
      await context.read<BusinessCardProvider>().loadScanHistory();
    }
  }

  // ── Copy text to clipboard ─────────────────────────────────
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ── Clear all scan history ─────────────────────────────────
  Future<void> _clearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear Scan History',
      message: 'Remove all scanned QR codes? This cannot be undone.',
      confirmLabel: 'Clear All',
    );
    if (confirmed && mounted) {
      await context.read<BusinessCardProvider>().clearScanHistory();
    }
  }

  // ── Format scan time ───────────────────────────────────────
  // Shows "Today 14:30", "Yesterday", "Jan 15", etc.
  String _formatScanTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scannedDay =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (scannedDay == today) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (scannedDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM d · HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: ModuleColors.qrCardLight,
        foregroundColor: ModuleColors.qrCard,
        actions: [
          // ── Clear all button (only shown if list has items) ─
          Consumer<BusinessCardProvider>(
            builder: (_, provider, __) {
              if (provider.scanHistory.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear All',
                onPressed: _clearAll,
              );
            },
          ),
        ],
      ),
      body: Consumer<BusinessCardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(label: 'Loading history...');
          }

          if (provider.scanHistory.isEmpty) {
            return EmptyState(
              icon: Icons.qr_code_scanner,
              title: 'No Scans Yet',
              message: 'Tap the camera button below to scan a QR code.',
              buttonLabel: 'Scan QR Code',
              onButtonPressed: _openScanner,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.md),
            itemCount: provider.scanHistory.length,
            itemBuilder: (context, index) {
              final scan = provider.scanHistory[index];
              return _ScanHistoryTile(
                scan: scan,
                formattedTime: _formatScanTime(scan.scannedAt),
                onCopy: () => _copyToClipboard(scan.scannedText),
                onDelete: () => provider.deleteScan(scan.id),
              );
            },
          );
        },
      ),

      // ── FAB: Open camera scanner ──────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: ModuleColors.qrCard,
        foregroundColor: Colors.white,
        tooltip: 'Scan QR Code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

// ── _ScanHistoryTile ──────────────────────────────────────────
//  Each row in the scan history list.
//  Uses Dismissible to enable swipe-to-delete.
// ─────────────────────────────────────────────────────────────
class _ScanHistoryTile extends StatelessWidget {
  final ScanHistory scan;
  final String formattedTime;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _ScanHistoryTile({
    required this.scan,
    required this.formattedTime,
    required this.onCopy,
    required this.onDelete,
  });

  // Detect what kind of content was scanned
  _ScanType get _scanType {
    final text = scan.scannedText;
    if (text.startsWith('BEGIN:VCARD')) return _ScanType.vcard;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return _ScanType.url;
    }
    if (text.contains('@') && text.contains('.')) return _ScanType.email;
    return _ScanType.text;
  }

  IconData get _scanIcon {
    switch (_scanType) {
      case _ScanType.vcard:  return Icons.contact_page_outlined;
      case _ScanType.url:    return Icons.link_rounded;
      case _ScanType.email:  return Icons.email_outlined;
      case _ScanType.text:   return Icons.text_snippet_outlined;
    }
  }

  String get _scanLabel {
    switch (_scanType) {
      case _ScanType.vcard:  return 'Contact Card';
      case _ScanType.url:    return 'URL';
      case _ScanType.email:  return 'Email';
      case _ScanType.text:   return 'Text';
    }
  }

  // Show a preview: hide full vCard, show raw text otherwise
  String get _displayText {
    if (_scanType == _ScanType.vcard) {
      // Extract FN (formatted name) from vCard
      final fnMatch = RegExp(r'FN:(.+)').firstMatch(scan.scannedText);
      return fnMatch != null ? fnMatch.group(1) ?? 'Contact' : 'Contact Card';
    }
    return scan.scannedText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      // Unique key is required for Dismissible to track each item
      key: Key(scan.id),
      // Swipe from right → left to delete
      direction: DismissDirection.endToStart,
      // Red background shown while swiping
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type icon ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModuleColors.qrCardLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_scanIcon,
                    color: ModuleColors.qrCard, size: 20),
              ),
              const SizedBox(width: 12),

              // ── Scan text ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type label + time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ModuleColors.qrCardLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _scanLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ModuleColors.qrCard,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formattedTime,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Content preview
                    Text(
                      _displayText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // ── Copy button ────────────────────────────────
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: 'Copy',
                onPressed: onCopy,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple enum to categorize scanned content type
enum _ScanType { vcard, url, email, text }
