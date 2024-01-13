import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musicapp_/main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late bool isSignIn;
  bool isFormInteracted = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool agreedToTerms = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    isSignIn = true; // Initially, set it to sign in
  }

  String? validateEmail(String? value) {
    if (isFormInteracted && (value == null || value.isEmpty)) {
      return 'Please enter your email';
    }

    if (value != null && !value.isEmpty) {
      // Custom email format validation
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (!isSignIn && isFormInteracted) {
      // Only validate during registration
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (!isSignIn) {
      // Only validate during registration
      if (isFormInteracted &&
          (value == null || value.isEmpty || value.length < 6)) {
        return 'Password must be at least 6 characters long';
      }
      if (value != null && value != passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  void switchAuthMode() {
    setState(() {
      isSignIn = !isSignIn;
      // Clear text controllers when switching modes
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      isFormInteracted = false;
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      isFormInteracted = true;
    });

    try {
      // Validation check before submission
      if ((validateEmail(emailController.text) != null ||
          validatePassword(passwordController.text) != null ||
          (isSignIn &&
              validateConfirmPassword(confirmPasswordController.text) !=
                  null))) {
        // Validation failed
        return;
      }

      if (!isSignIn && !agreedToTerms) {
        // Display an error message if terms are not agreed, but only for registration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please agree to the terms and conditions.',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color(0xFF27bc5c),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Additional check for registration to validate confirm password
      if (validatePassword(passwordController.text) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password must be at least 6 characters long',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color(0xFF27bc5c),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (validatePassword(confirmPasswordController.text) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password must be at least 6 characters long',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color(0xFF27bc5c),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Additional check for registration to validate confirm password
      if (!isSignIn &&
          isFormInteracted &&
          (confirmPasswordController.text.isEmpty ||
              confirmPasswordController.text != passwordController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Passwords do not match',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 230, 15, 0),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        isLoading = true; // Set loading state
      });

      if (isSignIn) {
        // Sign in logic
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } else {
        // Register logic
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      }

      // If successful, reset form interaction state and navigate to the main app
      setState(() {
        isFormInteracted = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          return MyApp(
            userEmail: FirebaseAuth.instance.currentUser!.email!,
          );
        }),
      );
    } on FirebaseAuthException catch (error) {
      // Handle specific authentication errors
      String errorMessage =
          'Authentication failed. please enter correct email or password';

      if (error.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      }

      // Display error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 230, 15, 0),
          content: Text(
            errorMessage,
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 228, 224, 224),
              fontSize: 15,
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );

      print("Authentication failed: $error");
    } catch (error) {
      // Handle other errors (e.g., display a generic error message to the user)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred. Please try again later.',
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: Color(0xFF27bc5c),
              fontSize: 15,
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      print("Authentication failed: $error");
    } finally {
      setState(() {
        isLoading = false; // Reset loading state
      });
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required String? Function(String?)? validator,
    required bool showPassword,
    required VoidCallback onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !showPassword : false,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: Colors.white,
        filled: true,
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                color: Colors.black,
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        errorText: validator != null ? validator(controller.text) : null,
      ),
      style: TextStyle(color: Colors.black),
    );
  }

  Widget buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(
          checkColor: Colors.white,
          activeColor: Colors.green,
          value: agreedToTerms,
          onChanged: (value) {
            setState(() {
              agreedToTerms = value ?? false;
            });
          },
        ),
        Text(
          'I agree to the terms and conditions',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset(
                'assets/login.png',
                height: 300,
                width: 300,
              ),
              buildTextField(
                controller: emailController,
                hintText: 'Email',
                icon: Icons.email,
                validator: validateEmail,
                showPassword: false,
                onTogglePassword: () {},                                        
              ),
              const SizedBox(height: 25),
              buildTextField(
                controller: passwordController,
                hintText: 'Password',
                icon: Icons.lock,
                isPassword: true,
                validator: validatePassword,
                showPassword: showPassword,
                onTogglePassword: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              ),
              if (!isSignIn) const SizedBox(height: 25),
              if (!isSignIn)
                buildTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  icon: Icons.lock,
                  isPassword: true,
                  validator: validateConfirmPassword,
                  showPassword: showConfirmPassword,
                  onTogglePassword: () {
                    setState(() {
                      showConfirmPassword = !showConfirmPassword;
                    });
                  },
                ),
              const SizedBox(height: 20),
              if (!isSignIn) buildAgreementCheckbox(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF27bc5c), // background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          isSignIn ? 'Sign In' : 'Register',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: switchAuthMode,
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSignIn
                                ? "Don't have an account?"
                                : 'Already have an account?',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            isSignIn ? 'Register here.' : 'Sign in here.',
                            style: TextStyle(
                              color: Colors.red,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
