import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prayoo/providers/auth_provider.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.purple.shade600],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.favorite, color: Colors.red, size: 28),
                              SizedBox(width: 8),
                              Text(AppConstants.appName,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (auth.errorMessage != null) ...[
                            Text(auth.errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                          ],
                          if (_isSignUp) ...[
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                  labelText: 'Display name'),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    final email = _emailController.text.trim();
                                    final password =
                                        _passwordController.text.trim();
                                    if (_isSignUp) {
                                      final ok = await auth.signUp(
                                          email, password,
                                          displayName:
                                              _nameController.text.trim());
                                      if (ok && mounted) {
                                        Navigator.pushReplacementNamed(
                                            context, '/profile');
                                      }
                                    } else {
                                      final ok =
                                          await auth.signIn(email, password);
                                      if (ok && mounted) {
                                        Navigator.pushReplacementNamed(
                                            context, '/profile');
                                      }
                                    }
                                  },
                            child: Text(auth.isLoading
                                ? 'Please wait...'
                                : (_isSignUp ? 'Create account' : 'Sign in')),
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    setState(() => _isSignUp = !_isSignUp);
                                  },
                            child: Text(_isSignUp
                                ? 'Have an account? Sign in'
                                : 'New here? Create an account'),
                          ),
                          if (!_isSignUp)
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/register');
                              },
                              child: const Text('Go to Registration'),
                            )
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
