import 'package:flutter/material.dart';
import '../services/docScanner_service.dart';
import '../services/docCreate_service.dart';

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
          _resultText = 'user canceld';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'failed';
        _resultText = 'error scan failed';
        _isScanning = false;
      });
    }
  }

  Future<void> _processScannedImage(String imagePath) async {
    setState(() {
      _status = 'creating pdf....';
    });
    try {
      final String pdfPath =
          await _fileService.CreatePdfFromImages([imagePath]);
      setState(() {
        _status = 'scanning completed, pdf created';
        _resultText = 'Pdf saved successfully at:\n$pdfPath';
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _status = 'pdf error';
        _resultText = 'pdf failed: $e';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext content) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('doc scanner'),
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
                'status: $_status',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      color: Colors.grey.shade700, fontStyle: FontStyle.italic),
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
                label:
                    Text(_isScanning ? 'scanning...' : 'start document scan'),
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
