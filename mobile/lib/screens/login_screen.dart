import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../widgets/glass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'asha');
  final _passwordController = TextEditingController(text: 'helper1234');
  late final TextEditingController _baseUrlController;
  bool _showServerField = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: context.read<AuthController>().baseUrl,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await context.read<AuthController>().signIn(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          baseUrl: _baseUrlController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/ezyhelper_logo_new.png',
                      height: 150,
                      semanticLabel: 'EzyHelpers',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Partner sign in',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to see the jobs assigned to you',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 32),
                    GlassContainer(
                      radius: 32,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Enter your username'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _showServerField = !_showServerField),
                              style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
                              icon: Icon(
                                _showServerField ? Icons.expand_less : Icons.expand_more,
                                size: 18,
                              ),
                              label: const Text('Server address'),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _showServerField
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                                    child: TextFormField(
                                      controller: _baseUrlController,
                                      keyboardType: TextInputType.url,
                                      autocorrect: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Backend base URL',
                                        helperText: 'Local emulator: http://10.0.2.2:8000',
                                        prefixIcon: Icon(Icons.dns_outlined),
                                      ),
                                      validator: (value) => (value == null || value.trim().isEmpty)
                                          ? 'Enter the backend address'
                                          : null,
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 10),
                            GlassContainer(
                              radius: 18,
                              shadow: false,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: const TextStyle(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          GlassButton(
                            label: 'Sign in',
                            icon: Icons.arrow_forward_rounded,
                            loading: auth.isSubmitting,
                            onPressed: auth.isSubmitting ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Demo login: asha / helper1234',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
