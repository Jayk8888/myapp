import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;
  bool signInSelected = true;
  bool loading = false;
  String? errorMessage;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> handleEmailAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.contains('@')) {
      setState(() {
        errorMessage = 'Enter a valid email.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      if (signInSelected) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = authErrorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> handleGhostAuth() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = authErrorMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'configuration-not-found':
        return 'Enable this sign-in method in Firebase Authentication.';
      case 'invalid-email':
        return 'Enter a valid email.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found with those credentials.';
      case 'wrong-password':
        return 'Password is incorrect.';
      case 'email-already-in-use':
        return 'That email already has an account.';
      case 'weak-password':
        return 'Use at least 6 characters.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF050510),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: 30,
            right: 30,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  40,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Whisper',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 52,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'CONFESS. ANONYMOUSLY.',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white.withValues(alpha: 0.22),
                      fontSize: 10,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 42),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              signInSelected = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'sign in',
                                    maxLines: 1,
                                    style: GoogleFonts.dmSerifDisplay(
                                      color: signInSelected
                                          ? Colors.white
                                          : Colors.white24,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 2,
                                  color: signInSelected
                                      ? Colors.white
                                      : Colors.white10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              signInSelected = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'create account',
                                    maxLines: 1,
                                    style: GoogleFonts.dmSerifDisplay(
                                      color: !signInSelected
                                          ? Colors.white
                                          : Colors.white24,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 2,
                                  color: !signInSelected
                                      ? Colors.white
                                      : Colors.white10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EMAIL',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 4,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'your email',
                      hintStyle: GoogleFonts.dmSerifDisplay(
                        color: Colors.white24,
                        fontSize: 20,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PASSWORD',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 4,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onSubmitted: (_) => loading ? null : handleEmailAuth(),
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '••••••••',
                      hintStyle: GoogleFonts.dmSerifDisplay(
                        color: Colors.white24,
                        fontSize: 20,
                      ),
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        child: Text(
                          obscurePassword ? 'show' : 'hide',
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFf87171),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 68,
                          child: ElevatedButton(
                            onPressed: loading ? null : handleEmailAuth,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              loading ? 'wait' : 'enter',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 68,
                          child: OutlinedButton(
                            onPressed: loading ? null : handleGhostAuth,

                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'ghost',
                              style: GoogleFonts.dmSerifDisplay(
                                color: Colors.white38,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
