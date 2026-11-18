import 'package:flutter/material.dart';
import 'package:goabusconnect/core/services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController();
  bool _register = false, _busy = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!SupabaseService.isInitialized) {
      setState(
        () => _message = 'OFFLINE DEMO · Account access requires Supabase configuration. Passenger demo browsing remains available.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = SupabaseService.client.auth;
      if (_register) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account action completed.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'Authentication failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_register ? 'Create passenger account' : 'Sign in'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        if (_register)
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_register ? 'Create account' : 'Sign in'),
        ),
        TextButton(
          onPressed: () => setState(() => _register = !_register),
          child: Text(
            _register
                ? 'Already have an account? Sign in'
                : 'Create an account',
          ),
        ),
        if (_message != null) Text(_message!),
      ],
    ),
  );
}
