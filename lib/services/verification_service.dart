import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationService {
  Future<Map<String, dynamic>> verifyProduct(String scannedHash) async {
    final query = await FirebaseFirestore.instance
        .collection("products")
        .where("qr_hash", isEqualTo: scannedHash)
        .get();

    // ❌ No matching product
    if (query.docs.isEmpty) {
      return {"status": "fake"};
    }

    final doc = query.docs.first;
    final data = doc.data();

    // ⚠️ Duplicate check
    if (data["status"] == "used") {
      await recordDuplicateScan(data);
      return {"status": "duplicate", "data": data};
    }

    // Mark as used
    await doc.reference.update({"status": "used"});

    // 📝 Record Log
    await FirebaseFirestore.instance.collection("logs").add({
      "event_type": "GENUINE_SCAN",
      "product_name": data["product_name"],
      "serial_number": data["serial_number"],
      "timestamp": FieldValue.serverTimestamp(),
      "status": "success",
    });

    return {"status": "genuine", "data": data};
  }

  Future<void> recordFakeScan(String hash) async {
    await FirebaseFirestore.instance.collection("logs").add({
      "event_type": "FAKE_SCAN_ATTEMPT",
      "scanned_hash": hash,
      "timestamp": FieldValue.serverTimestamp(),
      "status": "warning",
    });
  }

  Future<void> recordDuplicateScan(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection("logs").add({
      "event_type": "DUPLICATE_SCAN",
      "product_name": data["product_name"],
      "serial_number": data["serial_number"],
      "timestamp": FieldValue.serverTimestamp(),
      "status": "caution",
    });
  }
}
