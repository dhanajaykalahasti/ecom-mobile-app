import 'package:flutter/material.dart';

// Import your screens here
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/email_verification.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // The initial screen when app starts
      initialRoute: '/login',

      // Routes for screens without parameters
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationForm(),
      },

      // For routes that need parameters (like EmailVerificationScreen)
      onGenerateRoute: (settings) {
        if (settings.name == '/verify-email') {
          // Expecting an email String as argument
          final email = settings.arguments as String?;

          if (email == null) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Email not provided')),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              onVerificationComplete: (code) async {
                // Implement what happens on verification here,
                // or use a callback from the caller if you like.
                print('Verification code received: $code');
              },
              onResendCode: () async {
                // Implement resend code logic here
                print('Resend code called');
              },
            ),
          );
        }

        // Return null for unknown routes
        return null;
      },
    );
  }
}
