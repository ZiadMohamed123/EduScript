import 'dart:io';

import 'package:flutter/material.dart';
import '../services/docScanner_service.dart';
import '../services/docCreate_service.dart';
import '../providers/document_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/status_widget.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final DocumentScannerService _scannerService = DocumentScannerService();
  final FileService _fileService = FileService();
  String _status = 'ready to scan';
  String _resultText = 'Press the button to launch the document scanner.';
  bool _isScanning = false;
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

    final defaultName ='Scanned_Document_${_scannedImages.length}_pages_at((${DateTime.now()}))';

    final pdfName = await _askForPdfName(context, defaultName);

    if (pdfName == null || pdfName.isEmpty) return;

    setState(() {
      _status = 'Creating PDF...';
    });

    try {
      final pdfPath = await _fileService.createPdfFromImages(
        _scannedImages,
        fileName: pdfName,
      );

      final provider = Provider.of<DocumentProvider>(context, listen: false);
      provider.documentFile = File(pdfPath);

      await provider.extractStructuredFromPdf();

      setState(() {
        _status = 'Done';
        _resultText = 'Saved as:\n$pdfName.pdf';
        _scannedImages.clear();
      });
    } catch (e) {
      setState(() {
        _status = 'Failed';
        _resultText = '$e';
      });
    }
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
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter PDF name',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              statusWidget(_status),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _resultText,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Pages: ${_scannedImages.length}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scan Page'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _scannedImages.isEmpty ? null : _finishScan,
                icon: const Icon(Icons.check),
                label: const Text('Finish Document'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
