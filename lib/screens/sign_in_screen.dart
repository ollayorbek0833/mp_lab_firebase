import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import 'reset_password_screen.dart';

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

  final _auth = FirebaseAuth.instance;

  Future<void> _signInAsync() async {
    if (!_formKey.currentState!.validate()) return;

    // Optional: show a loading state (setState / button disabled) if you have state management
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
      );

      final user = cred.user ?? _auth.currentUser;

      if (user == null) {
        // Unexpected: signed-in credential but no user object
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-in succeeded but no user found.')));
        return;
      }

      // Success: navigate to Home (replace current route)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } on FirebaseAuthException catch (e) {
      var msg = 'Sign-in failed';
      if (e.code == 'user-not-found') msg = 'No account found for that email.';
      else if (e.code == 'wrong-password') msg = 'Incorrect password.';
      else if (e.code == 'invalid-email') msg = 'Invalid email.';
      else if (e.code == 'too-many-requests') msg = 'Too many attempts. Try later.';
      else if (e.message != null) msg = e.message!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      // Generic fallback
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      // Optional: hide loading state
    }
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
