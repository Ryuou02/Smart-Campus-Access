import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:smart_campus_access/pages/login.dart';
import 'package:smart_campus_access/screens/login_screen.dart';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;

class SecurityScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SecurityScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedQrCode;
  String _action = 'entry';
  Map<String, dynamic>? _scannedUser;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        setState(() {
          scannedQrCode = scanData.code;
        });
        final user = await mongo.MongoDBService.getUserByQrCodeId(scanData.code!);
        if (user != null && user['role'] == 'student') {
          setState(() {
            _scannedUser = user;
          });
          controller.pauseCamera();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid QR code or user not a student")),
          );
        }
      }
    });
  }

  Future<void> _logAccess() async {
    if (_scannedUser == null || scannedQrCode == null) return;

    final log = {
      'studentRollNumber': _scannedUser!['rollNumber'],
      'action': _action,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await mongo.MongoDBService.logAccess(log);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${_scannedUser!['rollNumber']} logged as $_action")),
    );

    setState(() {
      _scannedUser = null;
      scannedQrCode = null;
    });

    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Security Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.blueAccent,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_scannedUser != null) ...[
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                Text(
                                  "Student: ${_scannedUser!['rollNumber']}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ChoiceChip(
                                      label: const Text("Entry"),
                                      selected: _action == 'entry',
                                      onSelected: (selected) {
                                        setState(() {
                                          _action = 'entry';
                                        });
                                      },
                                      selectedColor: Colors.blueAccent,
                                      labelStyle: TextStyle(
                                        color: _action == 'entry' ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ChoiceChip(
                                      label: const Text("Exit"),
                                      selected: _action == 'exit',
                                      onSelected: (selected) {
                                        setState(() {
                                          _action = 'exit';
                                        });
                                      },
                                      selectedColor: Colors.blueAccent,
                                      labelStyle: TextStyle(
                                        color: _action == 'exit' ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildElevatedButton(
                                  onPressed: _logAccess,
                                  label: "Log $_action",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        const Center(
                          child: Text(
                            "Scan a student's QR code",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String label,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}