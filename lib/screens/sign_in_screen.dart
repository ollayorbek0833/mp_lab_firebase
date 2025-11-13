import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import 'sign_up_screen.dart';
import 'reset_password_screen.dart';

final _auth = FirebaseAuth.instance;

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    final r = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!r.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _signInAsync() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
      );
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        // show verification prompt
        await _auth.signOut();
        _showVerifyDialog();
      }
      // If verified, AuthGate will pick up authState and navigate to Home.
    } on FirebaseAuthException catch (e) {
      var msg = e.message ?? 'Sign-in failed';
      if (e.code == 'user-not-found') msg = 'No account found for that email.';
      if (e.code == 'wrong-password') msg = 'Incorrect password.';
      if (e.code == 'invalid-email') msg = 'Invalid email.';
      if (e.code == 'too-many-requests') msg = 'Too many attempts. Try later.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showVerifyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email not verified'),
          content: const Text('Please verify your email first. Check your inbox.'),
          actions: [
            TextButton(
              onPressed: () async {
                final email = _emailCtl.text.trim();
                try {
                  // find user by signing in with email & password quickly: or send verification from admin console.
                  // Simpler UX: send verification mail by creating a new temp sign-in and sending verification there
                  final tempCred = await _auth.signInWithEmailAndPassword(
                    email: email,
                    password: _passCtl.text,
                  );
                  await tempCred.user?.sendEmailVerification();
                  await _auth.signOut();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email resent')));
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Could not resend')));
                }
              },
              child: const Text('Resend verification'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Login',
              onPressedAsync: _signInAsync,
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())), child: const Text('Register')),
              const SizedBox(width: 8),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen())), child: const Text('Forgot password?')),
            ]),
          ]),
        ),
      ),
    );
  }
}
