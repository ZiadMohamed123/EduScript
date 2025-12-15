import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class ExtractionResultPage extends StatelessWidget {
  const ExtractionResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DocumentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Extracted Data")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Test Buttons
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Test",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => provider.loadDemoImage(),
                        icon: const Icon(Icons.image),
                        label: const Text("Load Demo Image"),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: provider.imageFile == null
                            ? null
                            : () async {
                                await provider.extract();
                              },
                        icon: const Icon(Icons.science),
                        label: const Text("Extract Data"),
                      ),
                      if (provider.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Results
              if (provider.document != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField("Title", provider.document!.title),
                        _buildField("Date", provider.document!.date),
                        _buildField("Student", provider.document!.studentName),
                        const SizedBox(height: 16),
                        const Text(
                          "Questions:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...provider.document!.questions
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "${entry.key + 1}. ${entry.value}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                )
              ] else if (!provider.isLoading)
                Center(
                  child: Text(
                    provider.imageFile == null
                        ? "No image loaded yet"
                        : "No data extracted yet",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              color: value == null ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
