import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class ExtractionResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DocumentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Extracted Data")),
      body: provider.document == null
          ? Center(child: Text("No data extracted"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text("Title: ${provider.document!.title ?? 'N/A'}"),
                  Text("Date: ${provider.document!.date ?? 'N/A'}"),
                  Text("Student: ${provider.document!.studentName ?? 'N/A'}"),
                  SizedBox(height: 20),
                  Text("Questions:", style: TextStyle(fontSize: 20)),
                  ...provider.document!.questions
                      .map((q) => ListTile(title: Text(q)))
                      .toList(),
                ],
              ),
            ),
    );
  }
}
