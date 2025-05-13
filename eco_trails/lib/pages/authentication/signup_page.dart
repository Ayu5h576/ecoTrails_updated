import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<StatefulWidget> createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      await credential.user!.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      context.go('/home');
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
      backgroundColor: Colors.white,
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
                  spacing: deviceHeight * 0.03,
                  children: [
                    Text(
                      'Sign Up',
                      style: GoogleFonts.poppins(
                        fontSize: deviceWidth * 0.15,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 74, 106, 94),
                      ),
                    ),
                    SizedBox(height: deviceHeight * 0.01),
                    _buildTextField(
                      'Full Name',
                      controller: _nameController,
                      validator: _validateRequired,
                    ),
                    _buildTextField(
                      'Phone Number',
                      controller: _phoneController,
                      validator: _validatePhone,
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
                    _buildTextField(
                      'Confirm Password',
                      isPassword: true,
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                      obscureText: !_showConfirmPassword,
                      toggleObscure: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        fixedSize: Size(deviceWidth * 0.8, deviceHeight * 0.06),
                        backgroundColor: Color.fromARGB(255, 92, 131, 116),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    GestureDetector(
                      child: Text("Already Have account ? Sign In"),
                      onTap: () {
                        (context).go('/signin');
                      },
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      validator: validator,
      obscuringCharacter: "*",
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromARGB(255, 38, 70, 83),
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
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
      style: GoogleFonts.poppins(
        fontSize: MediaQuery.of(context).size.width * 0.04,
        fontWeight: FontWeight.w300,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    );
  }

  String? _validateRequired(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  String? _validateEmail(String? value) =>
      (value == null || !value.contains('@')) ? 'Enter a valid email' : null;

  String? _validatePhone(String? value) =>
      (value == null || value.trim().length < 10)
          ? 'Enter a valid phone number'
          : null;

  String? _validatePassword(String? value) =>
      (value == null || value.length < 6)
          ? 'Password must be at least 6 characters'
          : null;

  String? _validateConfirmPassword(String? value) =>
      value != _passwordController.text ? 'Passwords do not match' : null;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
