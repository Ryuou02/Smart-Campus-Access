class User {
  final String email;
  final String password;
  final String role;
  final String rollNumber;
  final String? name;
  final String? qrCodeId;
  final String? photoData; 

  User({
    required this.email,
    required this.password,
    required this.role,
    required this.rollNumber,
    this.name,
    this.qrCodeId,
    this.photoData,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'role': role,
      'rollNumber': rollNumber,
      if (name != null) 'name': name,
      if (qrCodeId != null) 'qrCodeId': qrCodeId,
      if (photoData != null) 'photoData': photoData,
    };
  }
}