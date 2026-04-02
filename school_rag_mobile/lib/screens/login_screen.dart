import 'package:flutter/material.dart';
import 'home_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  String _role = 'Student';

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeDashboard(isAdmin: _role == 'Admin'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.school, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'Welcome to SchoolHub',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  labelText: 'Role',
                ),
                items: <String>['Student', 'Admin'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _role = newValue!;
                  });
                },
              ),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 18)),
              ),
              
              const SizedBox(height: 20),
              
              TextButton.icon(
                onPressed: () {
                  // FaceID/Fingerprint Placeholder Hook
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Biometric Sensor... (Placeholder)')),
                  );
                },
                icon: const Icon(Icons.fingerprint, size: 30),
                label: const Text('Login with Biometrics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
