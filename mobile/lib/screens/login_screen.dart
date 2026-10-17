import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';

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

    return Scaffold(
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
                    const Icon(Icons.cleaning_services, size: 56, color: Color(0xFF0D47A1)),
                    const SizedBox(height: 16),
                    Text(
                      'EzyHelpers Partner',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to see the jobs assigned to you',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Enter your username' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showServerField = !_showServerField),
                        icon: Icon(_showServerField ? Icons.expand_less : Icons.expand_more, size: 18),
                        label: const Text('Server address'),
                      ),
                    ),
                    if (_showServerField)
                      TextFormField(
                        controller: _baseUrlController,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Backend base URL',
                          helperText: 'Emulator: http://10.0.2.2:8000',
                          prefixIcon: Icon(Icons.dns_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Enter the backend address' : null,
                      ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFB71C1C), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: Color(0xFFB71C1C)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: auth.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Demo login: asha / helper1234',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
