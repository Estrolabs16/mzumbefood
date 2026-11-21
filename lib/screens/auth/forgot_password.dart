import 'package:flutter/material.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.forgotPassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mail_outline, size: 76, color: AppColors.primaryDark),
              const SizedBox(height: 18),
              const Text(
                'Reset your password',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and we will send you a reset link.',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_sent)
                SoftCard(
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read,
                          size: 56, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text(
                        'Reset link sent to ${_email.text.trim()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: S.email,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => value == null ||
                                !value.contains('@')
                            ? 'Enter a valid email address.'
                            : null,
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 14),
                        ErrorBanner(message: auth.error!),
                      ],
                      const SizedBox(height: 24),
                      auth.isBusy
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                              label: S.resetPassword,
                              onPressed: _submit,
                            ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
