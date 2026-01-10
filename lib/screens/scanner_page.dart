import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quiz_generator/screens/QuizCustomizationPage.dart';
import 'package:quiz_generator/screens/documents_list_page.dart';
import '../services/docScanner_service.dart';
import '../services/docCreate_service.dart';
import '../providers/document_provider.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final DocumentScannerService _scannerService = DocumentScannerService();
  final FileService _fileService = FileService();
  String _status = 'ready to scan';
  bool _isScanning = false;
  bool _isProcessing = false;
  final List<String> _scannedImages = [];

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _status = 'Scanning page ${_scannedImages.length + 1}...';
    });

    try {
      final List<String>? images = await _scannerService.scanPaper();

      if (images != null && images.isNotEmpty) {
        setState(() {
          _scannedImages.addAll(images);
          _status = 'Pages scanned: ${_scannedImages.length}';
          _isScanning = false;
        });
      } else {
        setState(() {
          _status = 'Canceled';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Scan failed';
        _isScanning = false;
      });
    }
  }

  Future<void> _finishScan() async {
    if (_scannedImages.isEmpty) return;

    final defaultName =
        'Scanned_Document_${_scannedImages.length}_pages_at((${DateTime.now()}))';

    final pdfName = await _askForPdfName(context, defaultName);

    if (pdfName == null || pdfName.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _status = 'Creating PDF...';
    });

    try {
      final pdfPath = await _fileService.createPdfFromImages(
        _scannedImages,
        fileName: pdfName,
      );

      final provider = Provider.of<DocumentProvider>(context, listen: false);

      setState(() {
        _status = 'Extracting text from document...';
      });

      provider.documentFile = File(pdfPath);
      try {
        await provider.extractStructuredFromPdf(pdfName);
      } catch (extractionError) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extraction failed: $extractionError'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (provider.document == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to extract document content. PDF may be invalid.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _status = 'ready to scan';
      });

      _showSuccessSheet(pdfName, provider, _scannedImages.length);
      setState(() {
        _scannedImages.clear();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessSheet(
      String pdfName, DocumentProvider provider, int pageCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface,
                      AppColors.blue50.withOpacity(0.5),
                    ],
                  ),
            color: isDark ? AppColors.surfaceDark : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.greenAccent],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Document Saved!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDarkVariant
                          : AppColors.blue50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pdfName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pageCount ${pageCount == 1 ? 'page' : 'pages'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSuccessButton(
                    icon: Icons.quiz,
                    label: 'Generate Quiz',
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizCustomizationPage(
                            documentId: provider.document!.documentId,
                            documentTitle: pdfName,
                            extractedText: provider.extractedRawText,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSuccessButton(
                    icon: Icons.summarize,
                    label: 'View Summary',
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.tealLight],
                    ),
                    onPressed: () {
                      final doc = Document(
                        id: provider.document!.documentId,
                        title: pdfName,
                        dateCreated: DateTime.now(),
                        pageCount: pageCount,
                      );
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/document-summary',
                        arguments: doc,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSuccessButton(
                    icon: Icons.folder_open,
                    label: 'Go to My Documents',
                    gradient: null,
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/documents');
                      setState(() {
                        _scannedImages.clear();
                        _status = 'ready to scan';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessButton({
    required IconData icon,
    required String label,
    Gradient? gradient,
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.primaryDarkVariant : AppColors.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextButton.icon(
            icon: Icon(icon,
                color:
                    isDark ? AppColors.primaryDarkVariant : AppColors.primary),
            label: Text(
              label,
              style: TextStyle(
                color:
                    isDark ? AppColors.primaryDarkVariant : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (gradient?.colors.first ?? AppColors.primary)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _askForPdfName(
      BuildContext context, String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Document Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: null,
              style: TextStyle(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter PDF name',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceDarkVariant
                    : AppColors.blue50.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.primaryDarkVariant.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.primaryDarkVariant.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
              child: ElevatedButton(
                onPressed: () {
                  final finalText = controller.text.trim();
                  Navigator.pop(context, finalText);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.background,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.background,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.cyan,
                        AppColors.accent
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.document_scanner,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Document',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        '${_scannedImages.length} ${_scannedImages.length == 1 ? 'page' : 'pages'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            color: isDark ? AppColors.backgroundDark : AppColors.background,
            child: Stack(
              children: [
                // Decorative floating circles
                if (!isDark)
                  Positioned(
                    top: 50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.cyan.withOpacity(0.15),
                            AppColors.cyan.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!isDark)
                  Positioned(
                    bottom: 100,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primary.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildStatusCard(_status, isDark),
                          const SizedBox(height: 32),
                          if (_scannedImages.isNotEmpty)
                            _buildPagesCard(_scannedImages.length, isDark)
                          else
                            _buildEmptyStateCard(isDark),
                          const SizedBox(height: 32),
                          _buildScanButton(isDark),
                          const SizedBox(height: 12),
                          _buildFinishButton(_scannedImages.length, isDark),
                          if (_scannedImages.isNotEmpty && !_isProcessing)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                'Ready to finish? Tap "Finish & Process" when done scanning.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.surface, AppColors.blue50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.cyan],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: _status,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'This may take a moment...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
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
    );
  }

  Widget _buildStatusCard(String status, bool isDark) {
    IconData icon;
    Color color;

    if (status.contains('Scanning')) {
      icon = Icons.document_scanner;
      color = AppColors.primary;
    } else if (status.contains('Creating')) {
      icon = Icons.picture_as_pdf;
      color = AppColors.orange;
    } else if (status.contains('Extracting')) {
      icon = Icons.text_fields;
      color = AppColors.teal;
    } else if (status.contains('Done') || status.contains('ready')) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (status.contains('Failed') ||
        status.contains('Error') ||
        status.contains('Canceled')) {
      icon = Icons.error;
      color = Colors.red;
    } else {
      icon = Icons.hourglass_empty;
      color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesCard(int pageCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$pageCount',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$pageCount ${pageCount == 1 ? 'page' : 'pages'} scanned',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan Page" to add more',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDarkVariant.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No pages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning a document',
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: _isScanning || _isProcessing
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.cyan, AppColors.accent],
              ),
        color: _isScanning || _isProcessing ? AppColors.textSecondary : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isScanning || _isProcessing
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isScanning || _isProcessing ? null : _startScan,
        icon: const Icon(Icons.document_scanner, color: Colors.white),
        label: const Text(
          'Scan Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishButton(int pageCount, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _scannedImages.isEmpty || _isProcessing
            ? Colors.grey[300]
            : Colors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _scannedImages.isEmpty || _isProcessing
            ? null
            : [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: _scannedImages.isEmpty || _isProcessing ? null : _finishScan,
        icon: Icon(
          Icons.check_circle,
          color: _scannedImages.isEmpty || _isProcessing
              ? Colors.grey[600]
              : Colors.white,
        ),
        label: Text(
          'Finish & Process ($pageCount ${pageCount == 1 ? 'page' : 'pages'})',
          style: TextStyle(
            color: _scannedImages.isEmpty || _isProcessing
                ? Colors.grey[600]
                : Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
