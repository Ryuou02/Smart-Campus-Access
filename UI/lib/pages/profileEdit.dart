import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;


class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileEditPage({Key? key, required this.user}) : super(key: key);
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _phoneController = TextEditingController(text: widget.user['phoneNumber']);
    _messageController = TextEditingController();
  }

  Future<void> _submitEditRequest() async {
    final _name = _nameController.text.trim();
    final _email = _emailController.text.trim();
    final _phoneNumber = _phoneController.text.trim();
    final _message = _messageController.text.trim();
    final _rollNumber = widget.user['rollNumber']; // Adjust as needed

    final updatedFields = {
      'name': _name,
      'phoneNumber': _phoneNumber,
      'email': _email,
      'message': _message,
    };

    final request = {
      'studentRollNumber': _rollNumber,
      'updatedFields': updatedFields,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await mongo.MongoDBService.createRequest(request);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit request submitted successfully!')),
      );
      Navigator.pop(context); // Optional: go back after success
    } catch (e) {
      print('Request error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.user['photoData'] != null
                          ? Image.memory(
                              base64Decode(widget.user['photoData']!),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('App No: ${widget.user['rollNumber']}'),
                        Text('Name: ${widget.user['name']}'),
                        Text('Phone: ${widget.user['phoneNumber']}'),
                        Text('Email: ${widget.user['email']}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitEditRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xCCB24507),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Edit', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
