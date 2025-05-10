import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

class MongoDBService {
  static const String _connectionString = "mongodb+srv://m_v_p:venkat_19@smartcampus.2pwzqo2.mongodb.net/smart_campus_db?retryWrites=true&w=majority&appName=smartcampus";
  static Db? _db;
  static DbCollection? _usersCollection;
  static DbCollection? _requestsCollection;
  static DbCollection? _feedbackFormsCollection;
  static DbCollection? _feedbackResponsesCollection;
  static DbCollection? _accessLogsCollection;
  static DbCollection? _attendanceLogsCollection;

  static Future<void> connect() async {
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();
      _usersCollection = _db!.collection('users');
      _requestsCollection = _db!.collection('requests');
      _feedbackFormsCollection = _db!.collection('feedback_forms');
      _feedbackResponsesCollection = _db!.collection('feedback_responses');
      _accessLogsCollection = _db!.collection('access_logs');
      _attendanceLogsCollection = _db!.collection('attendance_logs');
      print("Connected to MongoDB Atlas");
    } catch (e) {
      print("Error connecting to MongoDB: $e");
    }
  }

  static Future<void> close() async {
    await _db?.close();
  }

  static Future<void> insertUser(Map<String, dynamic> user) async {
    if (user['role'] == 'student') {
      // Generate a unique QR code ID for students
      user['qrCodeId'] = const Uuid().v4();
    }
    await _usersCollection?.insert(user);
  }

  static Future<Map<String, dynamic>?> findUser(String email, String password) async {
    final user = await _usersCollection?.findOne(where.eq('email', email).eq('password', password));
    print("Queried user with email: $email, found: $user");
    return user;
  }

  static Future<Map<String, dynamic>?> getUserByRollNumber(String rollNumber) async {
    return await _usersCollection?.findOne(where.eq('rollNumber', rollNumber));
  }

  static Future<Map<String, dynamic>?> getUserByQrCodeId(String qrCodeId) async {
    return await _usersCollection?.findOne(where.eq('qrCodeId', qrCodeId));
  }

  static Future<void> updateUserByRollNumber(String rollNumber, Map<String, dynamic> updatedFields) async {
    await _usersCollection?.update(
      where.eq('rollNumber', rollNumber),
      {'\$set': updatedFields},
    );
  }

  static Future<void> createRequest(Map<String, dynamic> request) async {
    await _requestsCollection?.insert(request);
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final requests = await _requestsCollection?.find(where.eq('status', 'pending')).toList();
    return requests?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> updateRequestStatus(ObjectId requestId, String status) async {
    await _requestsCollection?.update(
      where.eq('_id', requestId),
      {'\$set': {'status': status}},
    );
  }

  static Future<void> createFeedbackForm(Map<String, dynamic> form) async {
    await _feedbackFormsCollection?.insert(form);
  }

  static Future<List<Map<String, dynamic>>> getFeedbackFormsByFaculty(String facultyRollNumber) async {
    final forms = await _feedbackFormsCollection?.find(where.eq('facultyRollNumber', facultyRollNumber)).toList();
    return forms?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getAllFeedbackForms() async {
    final forms = await _feedbackFormsCollection?.find().toList();
    return forms?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> submitFeedbackResponse(Map<String, dynamic> response) async {
    await _feedbackResponsesCollection?.insert(response);
  }

  static Future<List<Map<String, dynamic>>> getFeedbackResponsesByFormId(String formId) async {
    final responses = await _feedbackResponsesCollection?.find(where.eq('formId', formId)).toList();
    return responses?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getAllFeedbackResponses() async {
    final responses = await _feedbackResponsesCollection?.find().toList();
    return responses?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final students = await _usersCollection?.find(where.eq('role', 'student')).toList();
    return students?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> logAccess(Map<String, dynamic> log) async {
    await _accessLogsCollection?.insert(log);
  }

  static Future<List<Map<String, dynamic>>> getAccessLogs() async {
    final logs = await _accessLogsCollection?.find().toList();
    return logs?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> logAttendance(Map<String, dynamic> attendance) async {
    await _attendanceLogsCollection?.insert(attendance);
  }

  static Future<List<Map<String, dynamic>>> getAttendanceLogsByFaculty(String facultyRollNumber) async {
    final logs = await _attendanceLogsCollection?.find(where.eq('facultyRollNumber', facultyRollNumber)).toList();
    return logs?.cast<Map<String, dynamic>>() ?? [];
  }
}