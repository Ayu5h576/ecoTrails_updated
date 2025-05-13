import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (userCredential.user != null) {
        print('Signed in as: ${userCredential.user?.email}');
        context.go('/home'); // 👈 navigate after successful sign-in
      } else {
        setState(() {
          _errorMessage = "Sign-in failed. Please try again.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/app/backGround.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Color.fromARGB(230, 230, 253, 245)),
          ),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: deviceWidth * 0.15,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 74, 106, 94),
                      ),
                    ),
                    _buildTextField(
                      'Email',
                      controller: _emailController,
                      validator: _validateEmail,
                    ),
                    _buildTextField(
                      'Password',
                      isPassword: true,
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: !_showPassword,
                      toggleObscure: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: deviceHeight * 0.02),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(deviceWidth * 0.8, deviceHeight * 0.06),
                        backgroundColor: const Color.fromARGB(
                          255,
                          92,
                          131,
                          116,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Robo',
                                ),
                              ),
                    ),
                    GestureDetector(
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text("Don't have an account? Sign Up"),
                      ),
                      onTap: () => context.go('/signup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        validator: validator,
        obscuringCharacter: '*',
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 38, 70, 83),
              width: 2.0,
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: toggleObscure,
                  )
                  : null,
        ),
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.04,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 38, 70, 83),
          fontFamily: 'Robo',
        ),
      ),
    );
  }

  String? _validateEmail(String? value) =>
      (value == null || !value.contains('@')) ? 'Enter a valid email' : null;

  String? _validatePassword(String? value) =>
      (value == null || value.length < 6)
          ? 'Password must be at least 6 characters'
          : null;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
