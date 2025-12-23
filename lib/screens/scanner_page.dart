import 'dart:io';

import 'package:flutter/material.dart';
import '../services/docScanner_service.dart';
import '../services/docCreate_service.dart';
import '../providers/document_provider.dart';
import 'package:provider/provider.dart';

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

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _status = 'launching scanner...';
      _resultText = '.....';
    });

    try {
      final String? imagePath = await _scannerService.scanPaper();

      if (imagePath != null) {
        await _processScannedImage(imagePath);
      } else {
        setState(() {
          _status = 'canceled';
          _resultText = 'User canceled';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'failed';
        _resultText = 'Error: scan failed';
        _isScanning = false;
      });
    }
  }

 Future<void> _processScannedImage(String imagePath) async {
  setState(() {
    _status = 'creating PDF...';
  });

  try {
    // 1️⃣ Create PDF from scanned image
    final String pdfPath = await _fileService.CreatePdfFromImages([imagePath]);

    // 2️⃣ Update provider's documentFile so extractStructured can run
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    provider.documentFile = File(pdfPath);

    // 3️⃣ Extract text / structured data from scanned image
    await provider.extractStructured(File(imagePath));

    // 4️⃣ Update UI
    setState(() {
      _status = 'Scan and extraction completed';
      _resultText = 'PDF saved at:\n$pdfPath';
      _isScanning = false;
    });
  } catch (e) {
    setState(() {
      _status = 'Error';
      _resultText = 'Scan or extraction failed: $e';
      _isScanning = false;
    });
  }
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
              Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
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
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(_isScanning ? 'Scanning...' : 'Start Document Scan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
