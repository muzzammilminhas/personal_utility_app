import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _db = DatabaseService();

  AdminDashboardData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _db.fetchAdminDashboardData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to leave the admin panel?',
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
    final email = context.watch<AuthProvider>().userEmail ?? 'Admin';

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
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Admin Panel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(context, email),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String email) {
    if (_isLoading) {
      return const LoadingWidget(label: 'Loading admin dashboard...');
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: ErrorDisplay(
              message:
                  'Could not load admin data. Make sure your admin email is configured and the admin SQL section has been run.\n\n$_errorMessage',
              onRetry: _loadData,
            ),
          ),
        ],
      );
    }

    final data = _data;
    if (data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 420,
            child: EmptyState(
              icon: Icons.dashboard_customize_outlined,
              title: 'No admin data',
              message: 'There is no dashboard data to show yet.',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildHeader(context, email),
        const SizedBox(height: AppSpacing.lg),
        _buildStatsGrid(context, data),
        const SizedBox(height: AppSpacing.lg),
        _buildRecentSection(
          context,
          title: 'Recent Business Cards',
          icon: Icons.badge_outlined,
          rows: data.recentCards,
          primaryBuilder: (row) => row['name'] as String? ?? 'Untitled card',
          secondaryBuilder: (row) =>
              row['email'] as String? ?? row['user_id'] as String? ?? '',
          dateKey: 'created_at',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildRecentSection(
          context,
          title: 'Recent Recordings',
          icon: Icons.mic_rounded,
          rows: data.recentRecordings,
          primaryBuilder: (row) =>
              row['title'] as String? ?? 'Untitled recording',
          secondaryBuilder: (row) {
            final duration = row['duration_ms'] as int? ?? 0;
            return 'Duration ${_formatDuration(duration)}';
          },
          dateKey: 'created_at',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildRecentSection(
          context,
          title: 'Recent QR Scans',
          icon: Icons.qr_code_scanner_rounded,
          rows: data.recentScans,
          primaryBuilder: (row) =>
              row['scanned_text'] as String? ?? 'Empty scan',
          secondaryBuilder: (row) => row['user_id'] as String? ?? '',
          dateKey: 'scanned_at',
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            'Admin signed in as $email',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String email) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Admin',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminDashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: constraints.maxWidth >= 720 ? 1.45 : 1.25,
          children: [
            _StatCard(
              label: 'Users',
              value: data.totalKnownUsers.toString(),
              icon: Icons.group_outlined,
              color: ModuleColors.qrCard,
            ),
            _StatCard(
              label: 'Cards',
              value: data.totalCards.toString(),
              icon: Icons.badge_outlined,
              color: ModuleColors.qrCard,
            ),
            _StatCard(
              label: 'Recordings',
              value: data.totalRecordings.toString(),
              icon: Icons.mic_rounded,
              color: ModuleColors.recorder,
            ),
            _StatCard(
              label: 'Scans',
              value: data.totalScans.toString(),
              icon: Icons.qr_code_scanner_rounded,
              color: ModuleColors.converter,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> rows,
    required String Function(Map<String, dynamic> row) primaryBuilder,
    required String Function(Map<String, dynamic> row) secondaryBuilder,
    required String dateKey,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (rows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              'No records yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...rows.map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(icon, color: theme.colorScheme.secondary),
                ),
                title: Text(
                  primaryBuilder(row),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  secondaryBuilder(row),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDate(row[dateKey] as String?),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(String? value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _formatDuration(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
