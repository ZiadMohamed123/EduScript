import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quiz_generator/screens/documents_list_page.dart';
import '../services/docScanner_service.dart';
import '../services/docCreate_service.dart';
import '../providers/document_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/status_widget.dart';
import 'quiz_generator_page.dart';

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
        await provider.extractStructuredFromPdf();
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
      });

      _showSuccessSheet(pdfName, provider, _scannedImages.length);
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
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.check_circle, color: Colors.green, size: 56),
              const SizedBox(height: 16),
              Text(
                'Document Saved!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                pdfName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$pageCount ${pageCount == 1 ? 'page' : 'pages'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.quiz),
                  label: const Text('Generate Quiz'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizGeneratorPage(
                          documentId: provider.document!.documentId,
                          documentTitle: pdfName,
                          extractedText: provider.extractedRawText,
                          autoGenerate: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.summarize),
                  label: const Text('View Summary'),
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
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Go to My Documents'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/documents');
                    setState(() {
                      _scannedImages.clear();
                      _status = 'ready to scan';
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askForPdfName(
      BuildContext context, String defaultName) async {
    final controller = TextEditingController(text: defaultName);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Document name'),
          content: SingleChildScrollView(
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Enter PDF name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('New Document (${_scannedImages.length} pages)'),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    statusWidget(_status),
                    const SizedBox(height: 40),
                    if (_scannedImages.isNotEmpty)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                '${_scannedImages.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_scannedImages.length} ${_scannedImages.length == 1 ? 'page' : 'pages'} scanned',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Scan Page" to add more',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.document_scanner,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pages yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start scanning a document',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed:
                          _isScanning || _isProcessing ? null : _startScan,
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scan Page'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _scannedImages.isEmpty || _isProcessing
                          ? null
                          : _finishScan,
                      icon: const Icon(Icons.check),
                      label: Text(
                          'Finish & Process (${_scannedImages.length} pages)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    if (_scannedImages.isNotEmpty && !_isProcessing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Ready to finish? Tap "Finish & Process" when done scanning.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a moment...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
