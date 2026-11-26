import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SystemLogsScreen extends StatelessWidget {
  const SystemLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "System Activity Logs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("logs")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, color: Colors.white24, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    "No activity logs recorded yet",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final eventType = data['event_type'] ?? 'UNKNOWN';
              final status = data['status'] ?? 'info';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final timeString = timestamp != null ? DateFormat('HH:mm:ss').format(timestamp) : '--:--:--';
              final dateString = timestamp != null ? DateFormat('MMM dd, yyyy').format(timestamp) : '';
              
              final productName = data['product_name'] ?? data['scanned_hash'] ?? 'N/A';
              
              Color statusColor;
              IconData eventIcon;

              switch (eventType) {
                case 'GENUINE_SCAN':
                  statusColor = Colors.greenAccent;
                  eventIcon = Icons.verified_user_rounded;
                  break;
                case 'FAKE_SCAN_ATTEMPT':
                  statusColor = Colors.redAccent;
                  eventIcon = Icons.warning_amber_rounded;
                  break;
                case 'DUPLICATE_SCAN':
                  statusColor = Colors.orangeAccent;
                  eventIcon = Icons.copy_rounded;
                  break;
                default:
                  statusColor = Colors.blueAccent;
                  eventIcon = Icons.info_outline_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(eventIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventType.replaceAll('_', ' '),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            productName,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "$dateString • $timeString",
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
