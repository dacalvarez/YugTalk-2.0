import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Authentication_Mod.dart';


class Verification_Widget extends StatefulWidget {
  const Verification_Widget({super.key});

  @override
  _Verification_WidgetState createState() => _Verification_WidgetState();
}

class _Verification_WidgetState extends State<Verification_Widget> {
  bool _isLoading = false;
  bool _verificationSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Welcome to YugTalk!',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You must be verified to login! Click the button below so that a verification email is sent to you!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Visibility(
              visible: !_isLoading && !_verificationSuccess,
              child: ElevatedButton(
                onPressed: () async {
                  // Start loading
                  setState(() {
                    _isLoading = true;
                  });

                  // Send email verification
                  try {
                    await sendVerificationEmail();

                    // Stop loading after sending verification
                    setState(() {
                      _isLoading = false;
                      _verificationSuccess = true;
                    });

                    // Show a SnackBar message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'A verification email has been sent! Please check your inbox.'
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Navigate back to AuthView after SnackBar duration
                    Future.delayed(const Duration(seconds: 1), () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Authentication_Mod(),
                        ),
                            (Route<dynamic> route) => false,
                      );
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending verification email: $e'),
                      ),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('Send Verification Email'),
              ),
            ),
            if (_isLoading)
              const CircularProgressIndicator(), // Loading indicator
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> sendVerificationEmail() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.sendEmailVerification();
      } else {
        throw Exception('No user is signed in.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email: $e'),
        ),
      );
      throw e;
    }
  }
}