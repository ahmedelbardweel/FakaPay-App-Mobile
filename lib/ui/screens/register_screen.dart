import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../theme.dart';
import '../../utils/device_utils.dart';
import '../../utils/translations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _idPhotoPath;
  String? _personalPhotoPath;
  bool _isPasswordVisible = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isIdPhoto) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (image != null) {
      setState(() {
        if (isIdPhoto) {
          _idPhotoPath = image.path;
        } else {
          _personalPhotoPath = image.path;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SingleChildScrollView(

        padding: const EdgeInsetsDirectional.only(start: 10, top: 80, end: 10, bottom: 10),

        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context, 'register'),
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel(S.of(context, 'personal_info')),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: S.of(context, 'full_name')),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: S.of(context, 'email')),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: S.of(context, 'mobile_number')),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),
              _sectionLabel(S.of(context, 'identity_verification')),
              TextField(
                controller: _idNumberController,
                decoration:
                    InputDecoration(labelText: S.of(context, 'id_passport_number')),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePicker(
                      label: S.of(context, 'id_photo'),
                      path: _idPhotoPath,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _buildImagePicker(
                      label: S.of(context, 'personal_photo'),
                      path: _personalPhotoPath,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _sectionLabel(S.of(context, 'security')),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'password'),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: AppTheme.gray400,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    InputDecoration(labelText: S.of(context, 'confirm_password')),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _handleRegister(authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1)),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                               strokeWidth: 2, color: AppTheme.white))
                      : Text(S.of(context, 'register')),
                ),
              ),
                const SizedBox(height: 15),
              ],
            ),
          ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required String? path,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppTheme.gray600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray200),
              color: AppTheme.gray100,
            ),
            child: path == null
                ? const Center(
                    child: Icon(Icons.add_a_photo_outlined,
                        color: AppTheme.gray400),
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: AppTheme.gray500,
          letterSpacing: 0,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Future<void> _handleRegister(AuthProvider authProvider) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final idNumber = _idNumberController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        idNumber.isEmpty ||
        password.isEmpty ||
        _idPhotoPath == null ||
        _personalPhotoPath == null) {
      _showError(S.of(context, 'complete_all_fields'));
      return;
    }

    if (password != confirmPassword) {
      _showError(S.of(context, 'passwords_dont_match'));
      return;
    }

    final deviceId = await DeviceUtils.getDeviceId();
    final success = await authProvider.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      deviceId: deviceId,
      idNumber: idNumber,
      idPhotoPath: _idPhotoPath!,
      personalPhotoPath: _personalPhotoPath!,
    );

    if (success && mounted) {
      Navigator.pop(context);
      _showSuccessDialog();
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'System registration failed');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          S.of(context, 'registration_submitted'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        content: Text(
          S.of(context, 'registration_pending_approval'),
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, 'ok'),
                style: const TextStyle(
                    color: AppTheme.primaryYellow, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
