import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class DocumentScannerService {
  final DocumentScanner documentScanner = DocumentScanner(
    options: DocumentScannerOptions(
      mode: ScannerMode.full,
      //potenial error in plugin name-----
      documentFormat: DocumentFormat.jpeg,
    ),
  );

  Future<String?> scanPaper() async {
    try {
      final DocumentScanningResult? result =
          await documentScanner.scanDocument();

      if (result != null && result.images.isNotEmpty) {
        final String firstImagePath = result.images.first;
        print('succesfully scanned img path: $firstImagePath');
        return firstImagePath;
      }
      return null;
    } catch (e) {
      print('document scanning error $e');
      return null;
    }
  }
}
