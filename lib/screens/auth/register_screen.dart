import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/app_strings.dart';
import '../../providers/AuthProvider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  String? _validateName(String? value, String lang) {
    if (value == null || value.trim().isEmpty)
      return AppStrings.t('name_required', lang);
    return null;
  }

  String? _validateEmail(String? value, String lang) {
    if (value == null || value.isEmpty)
      return AppStrings.t('email_required', lang);
    final regex = RegExp(r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return AppStrings.t('invalid_email', lang);
    return null;
  }

  String? _validatePassword(String? value, String lang) {
    if (value == null || value.length < 6) {
      return AppStrings.t('password_min', lang);
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on AppError catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      final lang = context.read<LocaleProvider>().languageCode;
      setState(() => _errorMessage = AppStrings.t('unknown_error', lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().languageCode;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('register', lang)),
        actions: [
          IconButton(
            icon: Text(
              lang == 'fr' ? 'EN' : 'FR',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            tooltip: AppStrings.t('language', lang),
            onPressed: () {
              context.read<LocaleProvider>().setLanguage(
                lang == 'fr' ? 'en' : 'fr',
              );
            },
          ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: AppStrings.t('dark_mode', lang),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('name', lang),
                ),
                validator: (v) => _validateName(v, lang),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('email', lang),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _validateEmail(v, lang),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('password', lang),
                ),
                obscureText: true,
                validator: (v) => _validatePassword(v, lang),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(AppStrings.t('create_account', lang)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
