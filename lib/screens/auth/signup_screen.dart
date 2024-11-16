import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../../main.dart';
import '../home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mq.width * .05),
          child: Column(
            children: [
              SizedBox(height: mq.height * .02),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: mq.height * .02),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: mq.height * .02),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: mq.height * .02),

              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: mq.height * .04),

              // Sign up button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(mq.width * .9, 45),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await APIs.auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (credential.user != null) {
          await credential.user!.updateDisplayName(_nameController.text);
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          if (e.code == 'weak-password') {
            Dialogs.showSnackbar(context, 'The password provided is too weak');
          } else if (e.code == 'email-already-in-use') {
            Dialogs.showSnackbar(
                context, 'An account already exists for that email');
          } else {
            Dialogs.showSnackbar(context, e.message ?? 'An error occurred');
          }
        }
      } catch (e) {
        if (mounted) {
          Dialogs.showSnackbar(context, 'An error occurred');
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 