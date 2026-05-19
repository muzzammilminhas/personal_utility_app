// ============================================================
//  screens/home/home_screen.dart  –  Main Dashboard
// ============================================================
//
//  This is the main screen users see after logging in.
//  It shows:
//  • A greeting with the user's email
//  • 3 module cards (QR Card, Converter, Recorder)
//  • Each card shows live item count from its provider
//  • Logout button in the AppBar
//
//  State:
//  • Reads AuthProvider          → user email + logout
//  • Reads BusinessCardProvider  → card count
//  • Reads RecordingProvider     → recording count
//  • Unit Converter has no stored data (no provider needed)
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/business_card_provider.dart';
import '../../providers/recording_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';

// Module screens (placeholders for Parts 3–5; stubs below)
import '../qr_card/card_list_screen.dart';
import '../converter/converter_screen.dart';
import '../recorder/recording_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data after the first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      context.read<BusinessCardProvider>().loadCards(),
      context.read<RecordingProvider>().loadRecordings(),
    ]);
  }

  Future<void> _handleLogout() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Stay',
    );
    if (confirm && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<AuthProvider>().userEmail ?? '';
    final username = email.contains('@') ? email.split('@').first : email;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.apps_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(AppStrings.appName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _loadAllData),
          IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: _handleLogout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(context, username),
              const SizedBox(height: AppSpacing.lg),
              Text('Your Modules',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              _buildQRCardModule(context),
              const SizedBox(height: AppSpacing.sm),
              _buildConverterModule(context),
              const SizedBox(height: AppSpacing.sm),
              _buildRecorderModule(context),
              const SizedBox(height: AppSpacing.xl),
              _buildFooter(context, email),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting banner ──────────────────────────────────────────
  Widget _buildGreetingCard(BuildContext context, String username) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting,',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(username,
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(AppStrings.appTagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  // ── QR Card module ───────────────────────────────────────────
  Widget _buildQRCardModule(BuildContext context) {
    final count = context.watch<BusinessCardProvider>().cards.length;
    return ModuleCard(
      title: AppStrings.qrCardModule,
      description: AppStrings.qrCardDesc,
      icon: Icons.badge_outlined,
      color: ModuleColors.qrCard,
      backgroundColor: ModuleColors.qrCardLight,
      itemCount: count,
      itemLabel: count == 1 ? 'card' : 'cards',
      onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CardListScreen()))
          .then((_) => _loadAllData()),
    );
  }

  // ── Converter module ─────────────────────────────────────────
  Widget _buildConverterModule(BuildContext context) {
    return ModuleCard(
      title: AppStrings.converterModule,
      description: AppStrings.converterDesc,
      icon: Icons.compare_arrows_rounded,
      color: ModuleColors.converter,
      backgroundColor: ModuleColors.converterLight,
      itemCount: 3,
      itemLabel: 'categories',
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ConverterScreen())),
    );
  }

  // ── Recorder module ──────────────────────────────────────────
  Widget _buildRecorderModule(BuildContext context) {
    final count = context.watch<RecordingProvider>().recordings.length;
    return ModuleCard(
      title: AppStrings.recorderModule,
      description: AppStrings.recorderDesc,
      icon: Icons.mic_rounded,
      color: ModuleColors.recorder,
      backgroundColor: ModuleColors.recorderLight,
      itemCount: count,
      itemLabel: count == 1 ? 'recording' : 'recordings',
      onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RecordingListScreen()))
          .then((_) => _loadAllData()),
    );
  }

  // ── Footer ────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, String email) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Text('Signed in as $email',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign Out'),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}