import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';  // Import the UUID package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QRGeneratorScreen(),
    );
  }
}

class QRGeneratorScreen extends StatefulWidget {
  @override
  _QRGeneratorScreenState createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  String _qrData = '';
  final Uuid _uuid = Uuid();

  void _generateQR() {
    setState(() {
      _qrData = _uuid.v4();  // Generate a new UUID v4
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _generateQR,
              child: const Text('Generate Unique QR Code'),
            ),
            const SizedBox(height: 20),
            _qrData.isNotEmpty
                ? Column(
                    children: [
                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 10),
                      SelectableText(  // Allows copying the UUID
                        'UUID: $_qrData',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : const Text('Tap the button to generate a QR code.'),
          ],
        ),
      ),
    );
  }
}
