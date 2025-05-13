import 'dart:convert'; // Added for base64 decoding
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IdCardWidget extends StatelessWidget {
  final String name;
  final String rollNumber;
  final String phoneNumber;
  final String year;
  final String degree;
  final String specialization;
  final String? photoData; // Changed to photoData (base64 string)
  final String qrCodeId;
  final VoidCallback? onReset;

  const IdCardWidget({
    Key? key,
    required this.name,
    required this.rollNumber,
    required this.phoneNumber,
    required this.year,
    required this.degree,
    required this.specialization,
    required this.photoData, // Changed to photoData
    required this.qrCodeId,
    this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: 350,
        ),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "SMART CAMPUS ID CARD",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: photoData != null
                          ? Image.memory(
                              base64Decode(photoData!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoText("NAME: $name"),
                          const SizedBox(height: 5),
                          _buildInfoText("Roll No: $rollNumber"),
                          const SizedBox(height: 5),
                          _buildInfoText("PHONE: $phoneNumber"),
                          const SizedBox(height: 5),
                          _buildInfoText("YEAR: $year"),
                          const SizedBox(height: 5),
                          _buildInfoText("Degree: $degree"),
                          const SizedBox(height: 5),
                          _buildInfoText("Specialization: $specialization"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: QrImageView(
                    data: qrCodeId,
                    version: QrVersions.auto,
                    size: 100.0,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(5),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.blueAccent,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Valid for current academic year",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent.shade400, Colors.blueAccent.shade700],
                    ),
                    border: const Border(
                      top: BorderSide(color: Colors.black, width: 2),
                      bottom: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Authorized Campus Stamp",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (onReset != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: onReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Back",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}