import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/errors.dart';
import '../../core/constants.dart';
import '../../core/app_strings.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/profile_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _loadingProfile = false;
  bool _loadingAvatar = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = context.read<LocaleProvider>().languageCode;
    setState(() {
      _loadingProfile = true;
      _errorMessage = null;
    });

    try {
      final service = ProfileService(context.read<ApiClient>());
      final updated = await service.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('profile_updated', lang))),
      );
    } on AppError catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.t('unknown_error', lang));
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final lang = context.read<LocaleProvider>().languageCode;

    setState(() {
      _loadingAvatar = true;
      _errorMessage = null;
    });

    try {
      final service = ProfileService(context.read<ApiClient>());
      final updated = await service.uploadAvatar(File(picked.path));
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('avatar_updated', lang))),
      );
    } on AppError catch (e) {
      // Gère notamment FILE_TOO_LARGE sans crash
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.t('unknown_error', lang));
    } finally {
      if (mounted) setState(() => _loadingAvatar = false);
    }
  }

  void _showImageSourceSheet() {
    final lang = context.read<LocaleProvider>().languageCode;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(AppStrings.t('take_photo', lang)),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppStrings.t('choose_from_gallery', lang)),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final lang = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('my_profile', lang))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? NetworkImage(_resolveAvatarUrl(user.avatarUrl))
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _loadingAvatar
                          ? const CircularProgressIndicator()
                          : InkWell(
                              onTap: _showImageSourceSheet,
                              child: const CircleAvatar(
                                radius: 16,
                                child: Icon(Icons.camera_alt, size: 16),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('name', lang),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.t('name_required', lang)
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('phone', lang),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _loadingProfile
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text(AppStrings.t('save', lang)),
                    ),
              const SizedBox(height: 24),
              const Divider(),
              SwitchListTile(
                title: Text(AppStrings.t('dark_mode', lang)),
                value: context.watch<ThemeProvider>().isDarkMode,
                onChanged: (_) => context.read<ThemeProvider>().toggle(),
              ),
              ListTile(
                title: Text(AppStrings.t('language', lang)),
                trailing: DropdownButton<String>(
                  value: context.watch<LocaleProvider>().languageCode,
                  items: const [
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (code) {
                    if (code != null) {
                      context.read<LocaleProvider>().setLanguage(code);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  AppStrings.t('logout', lang),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
