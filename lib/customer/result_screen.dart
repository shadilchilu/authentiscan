import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result["status"] == "fake") {
      return _buildUI("❌ Fake Product", Colors.red);
    }

    if (result["status"] == "duplicate") {
      return _buildUI("⚠️ Already Scanned", Colors.orange);
    }

    final data = result["data"];

    return Scaffold(
      appBar: AppBar(title: const Text("Verification Result")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "✅ Genuine Product",
              style: TextStyle(fontSize: 24, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text("Product: ${data["product_name"]}"),
            Text("Brand: ${data["brand"]}"),
            Text("Serial: ${data["serial_number"]}"),
          ],
        ),
      ),
    );
  }

  Widget _buildUI(String text, Color color) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification Result")),
      body: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
