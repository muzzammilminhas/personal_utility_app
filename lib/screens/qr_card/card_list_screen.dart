// ============================================================
//  screens/qr_card/card_list_screen.dart  –  Business Card List
// ============================================================
//
//  This is the main screen of the QR Business Card module.
//  It shows:
//  • A list of all the user's business card profiles
//  • FAB (Floating Action Button) to add a new card
//  • Tap a card → navigate to QR View screen
//  • Three-dot menu per card → edit / delete options
//  • AppBar action → navigate to Scan History screen
//
//  Data flow:
//    initState → provider.loadCards() → Supabase fetch
//    → _cards list updates → notifyListeners() → ListView rebuilds
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/business_card.dart';
import '../../providers/business_card_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import 'card_form_screen.dart';
import 'qr_view_screen.dart';
import 'scan_history_screen.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessCardProvider>().loadCards();
    });
  }

  void _openAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CardFormScreen(card: null)),
    );
  }

  void _openEditForm(BusinessCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardFormScreen(card: card)),
    );
  }

  void _openQRView(BusinessCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRViewScreen(card: card)),
    );
  }

  void _openScanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
    );
  }

  Future<void> _deleteCard(BusinessCard card) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Card',
      message: 'Delete "${card.name}"? This cannot be undone.',
    );
    if (confirmed && mounted) {
      final success =
          await context.read<BusinessCardProvider>().deleteCard(card.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(success ? '${card.name} deleted' : 'Failed to delete card'),
          backgroundColor:
              success ? null : Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Business Cards'),
        backgroundColor: ModuleColors.qrCardLight,
        foregroundColor: ModuleColors.qrCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Scan History',
            onPressed: _openScanHistory,
          ),
        ],
      ),
      body: Consumer<BusinessCardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget(label: 'Loading cards...');
          }
          if (provider.errorMessage != null) {
            return ErrorDisplay(
              message: provider.errorMessage!,
              onRetry: provider.loadCards,
            );
          }
          if (provider.cards.isEmpty) {
            return EmptyState(
              icon: Icons.badge_outlined,
              title: 'No Business Cards Yet',
              message:
                  'Tap the + button to create your first digital business card.',
              buttonLabel: 'Create Card',
              onButtonPressed: _openAddForm,
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadCards,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.cards.length,
              itemBuilder: (context, index) {
                final card = provider.cards[index];
                return _CardListTile(
                  card: card,
                  onTap: () => _openQRView(card),
                  onEdit: () => _openEditForm(card),
                  onDelete: () => _deleteCard(card),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: ModuleColors.qrCard,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Card'),
      ),
    );
  }
}

// ── _CardListTile ─────────────────────────────────────────────
//  A private widget for each card row.
//  Making it a separate StatelessWidget (not just a helper method)
//  lets Flutter rebuild individual tiles independently — better perf.
// ─────────────────────────────────────────────────────────────
class _CardListTile extends StatelessWidget {
  final BusinessCard card;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardListTile({
    required this.card,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // Build initials from name: "Ali Khan" → "AK", "Ali" → "A"
  String get _initials {
    final parts = card.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // ── Initials avatar ────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ModuleColors.qrCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Card info ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (card.jobTitle != null || card.company != null)
                      Text(
                        [card.jobTitle, card.company]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ModuleColors.qrCard,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (card.email != null || card.phone != null)
                      Text(
                        card.email ?? card.phone ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${DateFormat('MMM d, yyyy').format(card.createdAt)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),

              // ── Three-dot action menu ──────────────────────
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'qr') onTap();
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'qr',
                    child: ListTile(
                        leading: Icon(Icons.qr_code_rounded),
                        title: Text('View QR Code'),
                        contentPadding: EdgeInsets.zero,
                        dense: true),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit Card'),
                        contentPadding: EdgeInsets.zero,
                        dense: true),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                        dense: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
