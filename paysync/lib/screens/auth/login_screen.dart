import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/screens/auth/signup_screen.dart';
import 'package:paysync/screens/auth/user_details_screen.dart';
import 'package:paysync/screens/main_screen.dart';
import 'package:paysync/services/sync_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Check if user data exists in Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        // New user - navigate to UserDetails screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => UserDetailsScreen(
                    userId: userCredential.user!.uid,
                    email: userCredential.user!.email,
                    isGoogleSignIn: true,
                  ),
            ),
          );
        }
      } else {
        // Existing user - sync and navigate to MainScreen
        await SyncService.initialSync(userCredential.user!.uid);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        final user = await DatabaseHelper().getUser(userCredential.user!.uid);

        if (user != null) {
          // Sync user data before navigation
          await SyncService.initialSync(userCredential.user!.uid);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => UserDetailsScreen(
                    userId: userCredential.user!.uid,
                    email: userCredential.user!.email,
                    isGoogleSignIn: false,
                  ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildAnimatedFormField(
                        controller: _emailController,
                        icon: Icons.email,
                        label: 'Email',
                        delay: 100,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20),
                      _buildAnimatedFormField(
                        controller: _passwordController,
                        icon: Icons.lock,
                        label: 'Password',
                        delay: 200,
                        isPassword: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                _buildAnimatedButton(
                  onPressed: _isLoading ? null : _login,
                  label: 'Login',
                  delay: 300,
                ),
                SizedBox(height: 20),
                _buildDivider(),
                SizedBox(height: 20),
                _buildAnimatedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  isOutlined: true,
                  label: 'Continue with Google',
                  icon: Image.asset('assets/google_logo.jpg', height: 24),
                  delay: 400,
                ),
                SizedBox(height: 20),
                _buildAnimatedLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required int delay,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800),
      onEnd: () {
        Future.delayed(Duration(milliseconds: delay));
      },
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        validator:
            (value) =>
                value?.isEmpty ?? true ? 'Please enter your $label' : null,
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required String label,
    required int delay,
    bool isOutlined = false,
    Widget? icon,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600),
      onEnd: () {
        Future.delayed(Duration(milliseconds: delay));
      },
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: double.infinity,
        height: 55,
        child:
            isOutlined
                ? OutlinedButton.icon(
                  icon: icon ?? SizedBox(),
                  label: Text(label),
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                )
                : ElevatedButton(
                  onPressed: onPressed,
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('OR', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildAnimatedLinks() {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800),
      onEnd: () {
        Future.delayed(Duration(milliseconds: 500));
      },
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?"),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => SignupScreen()),
                    ),
                child: Text('Sign Up'),
              ),
            ],
          ),
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordScreen(),
                  ),
                ),
            child: Text('Forgot Password?'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
