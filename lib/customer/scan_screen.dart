import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/verification_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {

  bool scanned = false;

  final VerificationService verificationService = VerificationService();

  Future<void> checkProduct(String qr) async {
    final result = await verificationService.verifyProduct(qr);
    
    if (!mounted) return;

    if (result["status"] == "genuine") {
      final data = result["data"] ?? {};
      final createdAt = data["created_at"] as Timestamp?;
      final dateStr = createdAt != null 
          ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) 
          : "";
      await _showResultDialog("✅ Genuine!", data["product_name"] ?? "", data["brand"] ?? "", data["serial_number"] ?? "", "Genuine", date: dateStr);
    } else if (result["status"] == "duplicate") {
      // Record duplicate manually if verifyProduct doesn't do it (my update did it)
      await _showResultDialog("⚠️ Already Used", "Product already verified", "", "", "Duplicate", isError: true);
    } else {
      await verificationService.recordFakeScan(qr);
      await _showResultDialog("❌ Fake Product", "Not found in database", "", "", "Fake", isError: true);
    }

    if (mounted) {
      setState(() {
        scanned = false;
      });
    }
  }

  Future<void> _showResultDialog(String title, String name, String brand, String serial, String status, {String date = "", bool isError = false}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isError ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isError ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: isError ? Colors.redAccent : Colors.greenAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    color: isError ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isError ? "Warning: Authentication Failed" : "Authentic Product Verified",
                  style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1),
                ),
                const SizedBox(height: 30),
                _buildInfoRow(Icons.shopping_bag_outlined, "Product", name),
                _buildInfoRow(Icons.branding_watermark_outlined, "Brand", brand),
                _buildInfoRow(Icons.numbers_rounded, "Serial", serial),
                _buildInfoRow(Icons.calendar_today_rounded, "Registered", date),
                const SizedBox(height: 10),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Authentication Status", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isError ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: isError ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white10),
                      ),
                    ),
                    child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10)),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Product Verification"),
      ),
      body: Stack(
        children: [
          // 📷 Full Screen Scanner
          MobileScanner(
            onDetect: (BarcodeCapture capture) {
              if (scanned || capture.barcodes.isEmpty) return;
              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;
              if (code != null) {
                scanned = true;
                debugPrint("Scanned: $code");
                checkProduct(code);
              }
            },
          ),

          // 🔳 Professional Scanning Overlay
          _buildScannerOverlay(),

          // 📄 Floating Instructions
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blueAccent),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Point your camera at the product's QR code to verify authenticity.",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                // Corner Edges
                _buildCorner(0, 0, 1),
                _buildCorner(null, 1, 0, right: 0),
                _buildCorner(0, null, 1, bottom: 0),
                _buildCorner(null, null, 0, right: 0, bottom: 0),
                
                // Scanning Line Animation-like effect
                const Center(
                  child: Divider(color: Colors.blueAccent, thickness: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double? top, double? left, int rotate, {double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: RotatedBox(
        quarterTurns: rotate,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.blueAccent, width: 4),
              left: BorderSide(color: Colors.blueAccent, width: 4),
            ),
          ),
        ),
      ),
    );
  }
}