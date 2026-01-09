import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'documents_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final maxContentWidth = isLandscape ? 1200.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduScript'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: isLandscape
                ? SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 32.0 : 16.0,
                      vertical: isLandscape ? 16.0 : 16.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column - Header and Scan Button
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header Section
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.document_scanner,
                                        size: 48, color: Colors.white),
                                    SizedBox(height: 16),
                                    Text(
                                      'Welcome Back!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Scan documents and create study materials',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Scan Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Camera/Scanner feature coming soon!'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.camera_alt, size: 24),
                                label: const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Scan New Document',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Column - Action Cards and AI Tutor
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ActionCard(
                                icon: Icons.folder,
                                title: 'My Documents',
                                subtitle: 'View all your documents',
                                onTap: () {
                                  Navigator.pushNamed(context, '/documents');
                                },
                              ),
                              const SizedBox(height: 8),
                              _ActionCard(
                                icon: Icons.history,
                                title: 'Recents',
                                subtitle: 'Last 10 scanned documents',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DocumentsListPage(
                                              showRecentsOnly: true),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('AI Tutor feature coming soon!'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.school, size: 24),
                                label: const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'AI Tutor - Ask Questions',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 32.0 : 16.0,
                      vertical: isLandscape ? 16.0 : 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.document_scanner,
                                  size: 64, color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Scan documents and create study materials',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Main Action Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/scanner');
                          },
                          icon: const Icon(Icons.camera_alt, size: 28),
                          label: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Scan New Document',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Cards
                        _ActionCard(
                          icon: Icons.folder,
                          title: 'My Documents',
                          subtitle: 'View all your documents',
                          onTap: () {
                            Navigator.pushNamed(context, '/documents');
                          },
                        ),
                        const SizedBox(height: 8),
                        _ActionCard(
                          icon: Icons.history,
                          title: 'Recents',
                          subtitle: 'Last 10 scanned documents',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DocumentsListPage(
                                    showRecentsOnly: true),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // AI Tutor Button
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('AI Tutor feature coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.school, size: 32),
                          label: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'AI Tutor - Ask Questions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            minimumSize: const Size(double.infinity, 80),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 14.0 : 16.0,
            vertical: isLandscape ? 12.0 : 12.0,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isLandscape ? 8 : 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: isLandscape ? 20 : 24, color: AppColors.primary),
              ),
              SizedBox(width: isLandscape ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isLandscape ? 14 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isLandscape ? 2 : 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isLandscape ? 11 : 14, 
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: isLandscape ? 18 : 20),
            ],
          ),
        ),
      ),
    );
  }
}
