import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ecommerce/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _verificationStage = false;
  bool _verified = false;
  bool _registered = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

 Future<void> _registerUser() async {
   if (!_formKey.currentState!.validate()) return;

   setState(() {
     _loading = true;
     _errorMessage = null;
   });

   try {
     final response = await http.post(
       Uri.parse(ApiConstants.registerUrl),
       headers: {'Content-Type': 'application/json'},
       body: jsonEncode({
         'username': _nameController.text.trim(),
         'email': _emailController.text.trim(),
         'mobile': _mobileController.text.trim(),
         'password': _passwordController.text.trim(),
       }),
     );

     final data = jsonDecode(response.body);

     if (response.statusCode == 200) {
       setState(() {
         _verificationStage = true;
       });

       // Navigate to email verification screen here:
       Navigator.pushNamed(
         context,
         '/verify-email',
         arguments: _emailController.text.trim(),
       );

     } else {
       setState(() {
         _errorMessage = data['message'] ?? 'Registration failed. Please try again.';
       });
     }
   } catch (e) {
     setState(() {
       _errorMessage = 'Error: ${e.toString()}';
     });
   } finally {
     setState(() {
       _loading = false;
     });
   }
 }

  Widget _buildSuccess(String title, String message, VoidCallback onNext) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onNext,
              child: const Text("Next"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_registered) {
      return _buildSuccess(
        "Registration Successful!",
        "Your account has been created. Proceed to login.",
        () => Navigator.pushReplacementNamed(context, "/login"),
      );
    }

    if (_verified) {
      return _buildSuccess(
        "Email Verified!",
        "Email verified successfully. Click Next.",
        () => setState(() => _registered = true),
      );
    }

    if (_verificationStage) {
      // TODO: Replace with your EmailVerification widget/screen
      return Center(child: Text("Email Verification Component Here"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value == null || value.trim().length < 2 ? 'Name must be at least 2 characters' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => EmailValidator.validate(value ?? '') ? null : 'Enter a valid email',
            ),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (value) {
                if (value == null || !RegExp(r'^\d{10}$').hasMatch(value)) {
                  return 'Mobile number must be exactly 10 digits';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  value != null && value.length >= 6 ? null : 'Password must be at least 6 characters',
            ),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
              validator: (value) =>
                  value != _passwordController.text ? 'Passwords must match' : null,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registerUser,
                    child: const Text('Register'),
                  ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text("Already have an account? Login"),
            )
          ]),
        ),
      ),
    );
  }
}
