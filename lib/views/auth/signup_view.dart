// lib/views/auth/signup_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SignupView extends StatefulWidget {
  SignupView({Key? key}) : super(key: key);

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final AuthController auth = Get.find<AuthController>();
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final phoneC = TextEditingController();
  final garageC = TextEditingController();

  String role = 'user'; // default role
  bool loading = false;
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final err = await auth.signup(
      name: nameC.text.trim(),
      email: emailC.text.trim(),
      password: passC.text.trim(),
      phone: phoneC.text.trim(),
      role: role,
      garageName: role == 'mechanic' ? garageC.text.trim() : null,
    );
    setState(() => loading = false);

    if (err != null) {
      Get.snackbar('Signup failed', err,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
    } else {
      Get.snackbar(
          'Success', 'Account created — you will be logged in shortly.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black);
      // AuthController's listener should handle routing
    }
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    phoneC.dispose();
    garageC.dispose();
    super.dispose();
  }

  Widget _roleToggle(String value, IconData icon, String label) {
    final bool selected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.98) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.teal : Colors.grey.shade300,
              width: selected ? 1.6 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.teal.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.teal : Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.teal.shade800 : Colors.grey.shade800,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F9D58), Color(0xFF00BFA6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // logo
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.car_repair,
                          size: 72, color: Color(0xFF00BFA6)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Create an Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign up to request or provide roadside help',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name
                          TextFormField(
                            controller: nameC,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: Colors.teal),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 1.5),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Enter a valid name'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: emailC,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Colors.teal),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Enter an email';
                              final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!pattern.hasMatch(v.trim()))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: passC,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.teal),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6)
                                return 'Password must be at least 6 chars';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone Number
                          TextFormField(
                            controller: phoneC,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined,
                                  color: Colors.teal),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 1.5),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().length < 10)
                                ? 'Enter a valid phone number'
                                : null,
                          ),

                          const SizedBox(height: 18),

                          // Role selector label
                          Row(
                            children: const [
                              Icon(Icons.person_search, color: Colors.teal),
                              SizedBox(width: 8),
                              Text('I am a',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Role toggles
                          Row(
                            children: [
                              _roleToggle('user', Icons.person_outline, 'User'),
                              const SizedBox(width: 12),
                              _roleToggle('mechanic',
                                  Icons.build_circle_rounded, 'Mechanic'),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Additional field for mechanics (optional)
                          if (role == 'mechanic') ...[
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: garageC,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Garage / Business name (optional)',
                                prefixIcon: const Icon(
                                    Icons.store_mall_directory,
                                    color: Colors.teal),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.teal, width: 1.5),
                                ),
                              ),
                              validator: (v) {
                                // optional; no validation required
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 10),

                          // Signup button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding: EdgeInsets.zero,
                                elevation: 6,
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                shadowColor: MaterialStateProperty.all(
                                    Colors.transparent),
                              ),
                              onPressed: loading ? null : _submit,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0F9D58),
                                      Color(0xFF00BFA6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: loading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.4))
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // small note
                          Text(
                            'Note: For safety don’t self-select admin in production. Mechanics must be approved by an admin after signup.',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Text('Login',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
