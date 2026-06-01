import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business_card.dart';
import '../../providers/business_card_provider.dart';
import '../../utils/app_constants.dart';

class CardFormScreen extends StatefulWidget {
  final BusinessCard? card;

  const CardFormScreen({super.key, required this.card});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _jobTitleController =
        TextEditingController(text: widget.card?.jobTitle ?? '');
    _companyController =
        TextEditingController(text: widget.card?.company ?? '');
    _emailController = TextEditingController(text: widget.card?.email ?? '');
    _phoneController = TextEditingController(text: widget.card?.phone ?? '');
    _websiteController =
        TextEditingController(text: widget.card?.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BusinessCardProvider>();
    bool success;

    if (_isEditing) {
      final updatedCard = widget.card!.copyWith(
        name: _nameController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty
            ? null
            : _jobTitleController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );
      success = await provider.updateCard(updatedCard);
    } else {
      final newCard = BusinessCard(
        id: '',
        userId: '',
        name: _nameController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty
            ? null
            : _jobTitleController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      success = await provider.addCard(newCard);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Card updated successfully!' : 'Card created!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Save failed. Try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<BusinessCardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'New Business Card'),
        backgroundColor: ModuleColors.qrCardLight,
        foregroundColor: ModuleColors.qrCard,
        actions: [
          TextButton(
            onPressed: provider.isLoading ? null : _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: provider.isLoading
                    ? theme.colorScheme.outline
                    : ModuleColors.qrCard,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPreviewCard(theme),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(
                  theme, 'Basic Information', Icons.person_outline),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  helperText: 'This field is required',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _jobTitleController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _companyController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(
                  theme, 'Contact Details', Icons.contacts_outlined),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  prefixIcon: Icon(Icons.language_outlined),
                  hintText: 'https://example.com',
                ),
                onFieldSubmitted: (_) => _handleSave(),
              ),
              const SizedBox(height: AppSpacing.xl),
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModuleColors.qrCard,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(_isEditing
                          ? Icons.save_outlined
                          : Icons.add_circle_outline),
                      label: Text(
                        _isEditing ? 'Save Changes' : 'Create Card',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final name = _nameController.text.trim();
    final jobTitle = _jobTitleController.text.trim();
    final company = _companyController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ModuleColors.qrCard, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: ModuleColors.qrCard.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREVIEW',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'Your Name' : name,
            style: TextStyle(
              color: name.isEmpty
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (jobTitle.isNotEmpty || company.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [jobTitle, company].where((s) => s.isNotEmpty).join(' · '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          if (email.isNotEmpty) _previewRow(Icons.email_outlined, email),
          if (phone.isNotEmpty) _previewRow(Icons.phone_outlined, phone),
          if (email.isEmpty && phone.isEmpty)
            _previewRow(Icons.info_outline, 'Add contact info below',
                faded: true),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String text, {bool faded = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: Colors.white.withValues(alpha: faded ? 0.4 : 0.8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: faded ? 0.4 : 0.8),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ModuleColors.qrCard),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ModuleColors.qrCard,
          ),
        ),
      ],
    );
  }
}
