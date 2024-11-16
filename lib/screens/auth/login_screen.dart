import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../api/apis.dart';
import '../../helper/dialogs.dart';
import '../../main.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

//login screen -- implements google sign in or sign up feature for app
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    //for auto triggering animation
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isAnimate = true);
    });
  }

  // handles google login button click
  _handleGoogleBtnClick() {
    //for showing progress bar
    Dialogs.showLoading(context);

    _signInWithGoogle().then((user) async {
      //for hiding progress bar
      Navigator.pop(context);

      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if (await APIs.userExists() && mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch (e) {
      log('\n_signInWithGoogle: $e');

      if (mounted) {
        Dialogs.showSnackbar(context, 'Something Went Wrong (Check Internet!)');
      }

      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    //initializing media query (for getting device screen size)
    mq = MediaQuery.sizeOf(context);

    return Scaffold(
      //app bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to We Chat'),
      ),

      //body
      body: Stack(children: [
        //app logo
        AnimatedPositioned(
            top: mq.height * .15,
            right: _isAnimate ? mq.width * .25 : -mq.width * .5,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            child: Image.asset('assets/images/icon.png')),

        // Login form
        Positioned(
          top: mq.height * .3,
          left: mq.width * .05,
          width: mq.width * .9,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: mq.height * .03),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(mq.width * .9, 45),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),

                // Sign up link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),

                const Text('OR', style: TextStyle(fontSize: 16)),
                SizedBox(height: mq.height * .02),
              ],
            ),
          ),
        ),

        //google login button
        Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .06,
            child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                    shape: const StadiumBorder(),
                    elevation: 1),

                // on tap
                onPressed: _handleGoogleBtnClick,

                //google icon
                icon: Image.asset('assets/images/google.png',
                    height: mq.height * .03),

                //login with google label
                label: RichText(
                  text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      children: [
                        TextSpan(text: 'Login with '),
                        TextSpan(
                            text: 'Google',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ]),
                ))),
      ]),
    );
  }

  void _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await APIs.auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (credential.user != null) {
          if (await APIs.userExists() && mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else {
            await APIs.createUser().then((value) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            });
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          if (e.code == 'user-not-found') {
            Dialogs.showSnackbar(context, 'No user found with this email');
          } else if (e.code == 'wrong-password') {
            Dialogs.showSnackbar(context, 'Wrong password');
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
}
