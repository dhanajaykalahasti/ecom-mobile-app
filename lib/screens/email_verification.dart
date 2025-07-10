import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ecommerce/api_constants.dart';
import 'package:http/http.dart' as http;


class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final Future<void> Function(String code) onVerificationComplete;
  final Future<void> Function() onResendCode;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.onVerificationComplete,
    required this.onResendCode,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool loading = false;
  String? error;
  bool resendDisabled = false;
  int countdown = 60;
  Timer? _timer;

  void _startCountdown() {
    setState(() {
      resendDisabled = true;
      countdown = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown <= 1) {
        timer.cancel();
        setState(() {
          resendDisabled = false;
          countdown = 0;
        });
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => error = 'Please enter the code');
      return;
    }
    if (code.length < 4) {
      setState(() => error = 'Code must be at least 4 characters');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyEmailUrl), // Your verify API URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Verification success - navigate or update UI accordingly
        if (mounted) {
          // For example: Navigate back or to success screen
          Navigator.pop(context, true); // Return 'true' on success
        }
      } else {
        setState(() {
          error = data['message'] ?? 'Verification failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      resendDisabled = true;
      error = null;
    });
    _startCountdown();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resendVerificationUrl), // Your resend API URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        setState(() {
          error = data['message'] ?? 'Failed to resend code. Please try again.';
          resendDisabled = false;
        });
        _timer?.cancel();
      }
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        resendDisabled = false;
      });
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16.0),
              Text("We've sent a code to:"),
              Text(widget.email,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8.0),
              const Text("Please enter the code sent to your email",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24.0),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Code',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 6,
                keyboardType: TextInputType.text,
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: loading || _codeController.text.length < 4
                    ? null
                    : _handleVerify,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Email'),
              ),
              const SizedBox(height: 24.0),
              const Text("Didn't receive the code?"),
              TextButton(
                onPressed: resendDisabled ? null : _handleResendCode,
                child: Text(
                  resendDisabled
                      ? 'Resend code in ${countdown}s'
                      : 'Resend code',
                  style: TextStyle(
                      color: resendDisabled ? Colors.grey : Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
