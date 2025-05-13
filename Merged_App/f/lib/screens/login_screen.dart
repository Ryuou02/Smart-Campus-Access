
import 'package:flutter/material.dart';
import 'package:smart_campus_access/screens/admin_screen.dart';
import 'package:smart_campus_access/screens/faculty_screen.dart';
import 'package:smart_campus_access/screens/security_screen.dart';
import 'package:smart_campus_access/screens/student_screen.dart';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await mongo.MongoDBService.connect();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus Access',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final user = await mongo.MongoDBService.findUser(_email, _password);

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        switch (user['role']) {
          case 'admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminScreen(user: user)),
            );
            break;
          case 'student':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentScreen(user: user)),
            );
            break;
          case 'faculty':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FacultyScreen(user: user)),
            );
            break;
          case 'security':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SecurityScreen(user: user)),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid role")),
            );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 100,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Smart Campus Access",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Email',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value!,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            label: 'Password',
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value!,
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : _buildElevatedButton(
                                  onPressed: _login,
                                  label: "Login",
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: Icon(
          label == 'Email' ? Icons.email : Icons.lock,
          color: Colors.blueAccent,
        ),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:smart_campus_access/screens/admin_screen.dart';
// import 'package:smart_campus_access/screens/faculty_screen.dart';
// import 'package:smart_campus_access/screens/security_screen.dart';
// import 'package:smart_campus_access/screens/student_screen.dart';
// import 'package:smart_campus_access/services/mongodb_service.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String _email = '';
//   String _password = '';
//   String _role = 'student';
//   bool _isLoading = false;

//   Future<void> _login() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       setState(() => _isLoading = true);

//       final user = await MongoDBService.findUser(_email, _password);
//       setState(() => _isLoading = false);

//       if (user != null && user['role'].toString().toLowerCase() == _role.toLowerCase()) {
//         if (_role == 'student') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => StudentScreen(user: user),
//             ),
//           );
//         } else if (_role == 'admin') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const AdminScreen(),
//             ),
//           );
//         } else if (_role == 'faculty') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => FacultyScreen(user: user),
//             ),
//           );
//         } else if (_role == 'security') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => SecurityScreen(user: user),
//             ),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Invalid credentials or role")),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blueAccent.shade700, Colors.blueAccent.shade200],
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Card(
//               elevation: 10,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         "Smart Campus Login",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blueAccent,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       _buildTextField(
//                         label: 'Email',
//                         icon: Icons.email,
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter email';
//                           }
//                           if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) => _email = value!,
//                       ),
//                       const SizedBox(height: 15),
//                       _buildTextField(
//                         label: 'Password',
//                         icon: Icons.lock,
//                         obscureText: true,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter password';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) => _password = value!,
//                       ),
//                       const SizedBox(height: 15),
//                       DropdownButtonFormField<String>(
//                         value: _role,
//                         decoration: const InputDecoration(
//                           labelText: 'Role',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
//                           filled: true,
//                           fillColor: Colors.white,
//                         ),
//                         items: ['student', 'admin', 'faculty', 'security']
//                             .map((role) => DropdownMenuItem(
//                                   value: role,
//                                   child: Text(role),
//                                 ))
//                             .toList(),
//                         onChanged: (value) {
//                           setState(() => _role = value!);
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       _isLoading
//                           ? const CircularProgressIndicator()
//                           : _buildElevatedButton(
//                               onPressed: _login,
//                               label: "Login",
//                             ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required IconData icon,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//     required String? Function(String?) validator,
//     required void Function(String?) onSaved,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: Icon(icon, color: Colors.blueAccent),
//         filled: true,
//         fillColor: Colors.white,
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
//         ),
//       ),
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       validator: validator,
//       onSaved: onSaved,
//     );
//   }

//   Widget _buildElevatedButton({
//     required VoidCallback onPressed,
//     required String label,
//     IconData? icon,
//   }) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: icon != null ? Icon(icon, color: Colors.white) : const SizedBox.shrink(),
//       label: Text(
//         label,
//         style: const TextStyle(fontSize: 18, color: Colors.white),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.blueAccent,
//         padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         elevation: 5,
//       ),
//     );
//   }
// }
