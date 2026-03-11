// registration_screen.dart
// SCREEN 1: Collects Student Name, Register Number, Email
// Validates the form and saves to Firebase Firestore via Provider

import 'package:attendanceapp/provider/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'face_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AttendanceProvider>();

    final success = await provider.registerStudent(
      name: _nameController.text.trim(),
      registerNumber: _regNoController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FaceScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [

                  const SizedBox(height: 40),

                  const Icon(
                    Icons.school,
                    size: 70,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Smart Attendance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text(
                    "Step 1 of 3 — Student Registration",
                    style: TextStyle(color: Colors.white54),
                  ),

                  const SizedBox(height: 40),

                  _buildProgressBar(1),

                  const SizedBox(height: 40),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        _buildTextField(
                          controller: _nameController,
                          label: "Full Name",
                          icon: Icons.person,
                          hint: "Enter your full name",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Name required";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _regNoController,
                          label: "Register Number",
                          icon: Icons.badge,
                          hint: "21CS001",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Register number required";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email,
                          hint: "student@email.com",
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email required";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  if (provider.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        provider.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          provider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "Continue to Face Registration",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: index < step
                  ? const Color(0xFF6C63FF)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}