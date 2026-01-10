import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  XFile? _selectedXFile; // Store XFile to access mimeType
  Uint8List? _currentProfilePicture; // Current profile picture from API
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen to changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_isLoading) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
      });
      // Load current profile picture
      await _loadCurrentProfilePicture();
    }
  }

  Future<void> _loadCurrentProfilePicture() async {
    try {
      final pictureBytes = await _userService.getProfilePicture();
      if (mounted) {
        setState(() {
          _currentProfilePicture = pictureBytes;
        });
      }
    } catch (e) {
      // Profile picture not found or error loading - use default
      if (mounted) {
        setState(() {
          _currentProfilePicture = null;
        });
      }
    }
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_currentProfilePicture != null) {
      return MemoryImage(_currentProfilePicture!);
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: true, // Need metadata to get mimeType
      );
      
      if (image != null && mounted) {
        // Debug: Print image info
        print('Selected image path: ${image.path}');
        print('Selected image name: ${image.name}');
        print('Selected image mimeType: ${image.mimeType}');
        
        setState(() {
          _selectedImage = File(image.path);
          _selectedXFile = image; // Store XFile to access mimeType
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error picking image';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant photo library access in app settings.';
        } else if (e.toString().contains('PlatformException')) {
          errorMessage = 'Unable to access photo library. Please check app permissions.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              _buildImageActionTile(
                context,
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.cyan],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (_selectedImage != null)
                _buildImageActionTile(
                  context,
                  icon: Icons.delete,
                  title: 'Remove Photo',
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.redAccent],
                  ),
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _selectedXFile = null;
                      _hasChanges = true;
                    });
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? Colors.red
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      
      // Check if there are actual changes
      final currentUser = await AuthService().getCurrentUser();
      if (currentUser != null) {
        final nameChanged = name != currentUser.name;
        final emailChanged = email != currentUser.email;
        
        if (!nameChanged && !emailChanged && _selectedImage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No changes to save')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Update profile via API
      final result = await _userService.updateProfile(
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        profilePicture: _selectedImage,
        mimeType: _selectedXFile?.mimeType, // Pass mimeType from XFile
      );

      // Refresh user data from API after successful update
      if (result['user'] != null && mounted) {
        // Refresh AuthController to fetch updated user data from API
        await AuthController().refreshUser();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload profile picture if a new one was uploaded
        if (_selectedImage != null) {
          await _loadCurrentProfilePicture();
        }
        
        setState(() {
          _hasChanges = false;
          _selectedImage = null; // Clear selected image after successful save
          _selectedXFile = null;
        });
        
        // Optionally navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final maxContentWidth = isLandscape ? 700.0 : double.infinity;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.blue50.withOpacity(0.4),
                    AppColors.cyanLight.withOpacity(0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
        ),
        child: Stack(
          children: [
            // Decorative background shapes
            if (!isDark) ...[
              Positioned(
                top: 50,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cyanLight.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.indigoLight.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 40 : 20,
                    vertical: isLandscape ? 20 : 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: isLandscape
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Profile Picture
                        Expanded(
                          flex: 1,
                          child: Builder(
                            builder: (context) {
                              return Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 80,
                                            backgroundColor: Colors.white,
                                            backgroundImage: _getProfileImage(),
                                            child: _selectedImage == null && _currentProfilePicture == null
                                                ? Icon(
                                                    Icons.person,
                                                    size: 80,
                                                    color: AppColors.primary,
                                                  )
                                                : null,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.primary, AppColors.cyan],
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: CircleAvatar(
                                                radius: 24,
                                                backgroundColor: Colors.transparent,
                                                child: IconButton(
                                                  icon: const Icon(Icons.camera_alt, size: 22, color: Colors.white),
                                                  onPressed: _showImageSourceDialog,
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.primary, AppColors.cyan],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: TextButton.icon(
                                        onPressed: _showImageSourceDialog,
                                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                        label: const Text(
                                          'Change Photo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Right side - Form Fields
                        Expanded(
                          flex: 2,
                          child: Builder(
                            builder: (context) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Name Field
                                  Builder(
                                    builder: (context) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDark
                                                  ? Colors.black.withOpacity(0.25)
                                                  : AppColors.primary.withOpacity(0.12),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                              spreadRadius: 0.5,
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller: _nameController,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Name',
                                            hintText: 'Enter your name',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(12),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.primary, AppColors.cyan],
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.person, color: Colors.white, size: 20),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: AppColors.primary,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            labelStyle: TextStyle(
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondary,
                                            ),
                                            hintStyle: TextStyle(
                                              color: isDark
                                                  ? AppColors.textSecondaryDark.withOpacity(0.6)
                                                  : AppColors.textSecondary.withOpacity(0.6),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter your name';
                                            }
                                            return null;
                                          },
                                          textCapitalization: TextCapitalization.words,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                              // Email Field
                              Builder(
                                builder: (context) {
                                  final scheme = Theme.of(context).colorScheme;
                                  final isDark = scheme.brightness == Brightness.dark;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? Colors.black.withOpacity(0.25)
                                              : AppColors.primary.withOpacity(0.12),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _emailController,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'Enter your email',
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AppColors.cyan, AppColors.primary],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.email, color: Colors.white, size: 20),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: AppColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        labelStyle: TextStyle(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? AppColors.textSecondaryDark.withOpacity(0.6)
                                              : AppColors.textSecondary.withOpacity(0.6),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Save Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: _hasChanges && !_isLoading
                                      ? const LinearGradient(
                                          colors: [AppColors.primary, AppColors.cyan, AppColors.primaryDark],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: _hasChanges && !_isLoading
                                      ? null
                                      : (isDark
                                          ? AppColors.surfaceDarkVariant
                                          : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: _hasChanges && !_isLoading
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.4),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                            spreadRadius: 1,
                                          ),
                                          BoxShadow(
                                            color: AppColors.cyan.withOpacity(0.25),
                                            blurRadius: 12,
                                            offset: const Offset(-2, -2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Picture Section
                        Builder(
                          builder: (context) {
                            return Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Colors.white,
                                          backgroundImage: _getProfileImage(),
                                          child: _selectedImage == null && _currentProfilePicture == null
                                              ? Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: AppColors.primary,
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [AppColors.primary, AppColors.cyan],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.transparent,
                                              child: IconButton(
                                                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                                onPressed: _showImageSourceDialog,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary, AppColors.cyan],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: TextButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                      label: const Text(
                                        'Change Photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Name Field
                        Builder(
                          builder: (context) {
                            final scheme = Theme.of(context).colorScheme;
                            final isDark = scheme.brightness == Brightness.dark;
                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.25)
                                        : AppColors.primary.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  hintText: 'Enter your name',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primary, AppColors.cyan],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark.withOpacity(0.6)
                                        : AppColors.textSecondary.withOpacity(0.6),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                textCapitalization: TextCapitalization.words,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Email Field
                        Builder(
                          builder: (context) {
                            final scheme = Theme.of(context).colorScheme;
                            final isDark = scheme.brightness == Brightness.dark;
                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.25)
                                        : AppColors.primary.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.cyan, AppColors.primary],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.email, color: Colors.white, size: 20),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark.withOpacity(0.6)
                                        : AppColors.textSecondary.withOpacity(0.6),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Save Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: _hasChanges && !_isLoading
                                ? const LinearGradient(
                                    colors: [AppColors.primary, AppColors.cyan, AppColors.primaryDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _hasChanges && !_isLoading
                                ? null
                                : (isDark
                                    ? AppColors.surfaceDarkVariant
                                    : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _hasChanges && !_isLoading
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: AppColors.cyan.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}