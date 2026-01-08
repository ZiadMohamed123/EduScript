
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String> createPdfFromImages(
  List<String> imagePaths, {
  required String fileName,
}) async {
  final pdf = pw.Document();

  for (final path in imagePaths) {
    final image = pw.MemoryImage(File(path).readAsBytesSync());
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image));
        },
      ),
    );
  }

  final output = await getTemporaryDirectory();

  final safeName = fileName
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(' ', '_');

  final file = File('${output.path}/$safeName.pdf');
  await file.writeAsBytes(await pdf.save());

  return file.path;
}

}
