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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _selectedXFile = null;
                    _hasChanges = true;
                  });
                },
              ),
          ],
        ),
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: Center(
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
                              final scheme = Theme.of(context).colorScheme;
                              final isDark = scheme.brightness == Brightness.dark;
                              return Center(
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 80,
                                          backgroundColor: isDark
                                              ? scheme.surfaceVariant.withOpacity(0.5)
                                              : AppColors.primary.withOpacity(0.1),
                                          backgroundImage: _getProfileImage(),
                                          child: _selectedImage == null && _currentProfilePicture == null
                                              ? Icon(
                                                  Icons.person,
                                                  size: 80,
                                                  color: isDark
                                                      ? scheme.onSurfaceVariant
                                                      : AppColors.primary,
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundColor: AppColors.primary,
                                            child: IconButton(
                                              icon: const Icon(Icons.camera_alt, size: 22, color: Colors.white),
                                              onPressed: _showImageSourceDialog,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: Icon(Icons.edit, color: scheme.primary),
                                      label: Text(
                                        'Change Photo',
                                        style: TextStyle(color: scheme.primary),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

              // Name Field
              Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  final isDark = scheme.brightness == Brightness.dark;
                  return TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: scheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person, color: scheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  );
                },
              ),
              const SizedBox(height: 20),

                              // Name Field
                              Builder(
                                builder: (context) {
                                  final scheme = Theme.of(context).colorScheme;
                                  final isDark = scheme.brightness == Brightness.dark;
                                  return TextFormField(
                                    controller: _nameController,
                                    style: TextStyle(color: scheme.onSurface),
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      hintText: 'Enter your name',
                                      prefixIcon: Icon(Icons.person, color: scheme.primary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: scheme.outline),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: scheme.outline),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: scheme.primary, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
                                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                                      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                    textCapitalization: TextCapitalization.words,
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              // Email Field
                              Builder(
                                builder: (context) {
                                  final scheme = Theme.of(context).colorScheme;
                                  final isDark = scheme.brightness == Brightness.dark;
                                  return TextFormField(
                                    controller: _emailController,
                                    style: TextStyle(color: scheme.onSurface),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'Enter your email',
                                      prefixIcon: Icon(Icons.email, color: scheme.primary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: scheme.outline),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: scheme.outline),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: scheme.primary, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
                                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                                      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
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
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Save Button
                              ElevatedButton(
                                onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ],
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
                            final scheme = Theme.of(context).colorScheme;
                            final isDark = scheme.brightness == Brightness.dark;
                            return Center(
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 60,
                                        backgroundColor: isDark
                                            ? scheme.surfaceVariant.withOpacity(0.5)
                                            : AppColors.primary.withOpacity(0.1),
                                        backgroundImage: _getProfileImage(),
                                        child: _selectedImage == null && _currentProfilePicture == null
                                            ? Icon(
                                                Icons.person,
                                                size: 60,
                                                color: isDark
                                                    ? scheme.onSurfaceVariant
                                                    : AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.primary,
                                          child: IconButton(
                                            icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                            onPressed: _showImageSourceDialog,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _showImageSourceDialog,
                                    icon: Icon(Icons.edit, color: scheme.primary),
                                    label: Text(
                                      'Change Photo',
                                      style: TextStyle(color: scheme.primary),
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
                            return TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: scheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: 'Enter your name',
                                prefixIcon: Icon(Icons.person, color: scheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
                                labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Email Field
                        Builder(
                          builder: (context) {
                            final scheme = Theme.of(context).colorScheme;
                            final isDark = scheme.brightness == Brightness.dark;
                            return TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: scheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email, color: scheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: scheme.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.3 : 0.7),
                                labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
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
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Save Button
                        ElevatedButton(
                          onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
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

