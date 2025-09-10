import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prayoo/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sign up with email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (auth.errorMessage != null) ...[
                          Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Display name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  final ok = await auth.signUp(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    displayName: _nameController.text.trim(),
                                  );
                                  if (ok && mounted) {
                                    Navigator.pushReplacementNamed(context, '/profile');
                                  }
                                },
                          icon: const Icon(Icons.person_add),
                          label: Text(auth.isLoading ? 'Please wait...' : 'Create account'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
