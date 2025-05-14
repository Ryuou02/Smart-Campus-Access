import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

class MongoDBService {
  static const String _connectionString =
      "mongodb+srv://m_v_p:Venkat_19@smart-campus.r7orvf4.mongodb.net/smart_campus_db?retryWrites=true&w=majority&appName=smart-campus&connectTimeoutMS=10000&socketTimeoutMS=30000";
  // static const String _connectionString =
  //     "mongodb+srv://m_v_p:venkat_19@smartcampus.2pwzqo2.mongodb.net/smart_campus_db?retryWrites=true&w=majority&appName=smartcampus";

  static Db? _db;
  static DbCollection? _usersCollection;
  static DbCollection? _requestsCollection;
  static DbCollection? _feedbackFormsCollection;
  static DbCollection? _feedbackResponsesCollection;
  static DbCollection? _accessLogsCollection;
  static DbCollection? _attendanceLogsCollection;
  static DbCollection? _coursesCollection;
  static DbCollection? _studentCoursesCollection;
  static bool _isConnecting = false;

  static Future<void> connect() async {
    try {
      if (_db != null && _db!.isConnected) {
        print("MongoDB already connected");
        return;
      }
      print("Connecting to MongoDB Atlas...");
      _db = await Db.create(_connectionString);
      await _db!.open();
      _usersCollection = _db!.collection('users');
      _requestsCollection = _db!.collection('requests');
      _feedbackFormsCollection = _db!.collection('feedback_forms');
      _feedbackResponsesCollection = _db!.collection('feedback_responses');
      _accessLogsCollection = _db!.collection('access_logs');
      _attendanceLogsCollection = _db!.collection('access_logs');
      _coursesCollection = _db!.collection('courses');
      _studentCoursesCollection = _db!.collection('student_courses');
      print("Connected to MongoDB Atlas");
    } catch (e) {
      print("Error connecting to MongoDB: $e");
      _db = null; // Clear invalid connection
      rethrow; // Let the caller handle the error
    }
  }

  static Future<void> close() async {
    try {
      if (_db != null && _db!.isConnected) {
        await _db!.close();
        print("MongoDB connection closed");
      }
    } catch (e) {
      print("Error closing MongoDB connection: $e");
    } finally {
      _db = null;
      _usersCollection = null;
      _requestsCollection = null;
      _feedbackFormsCollection = null;
      _feedbackResponsesCollection = null;
      _accessLogsCollection = null;
      _attendanceLogsCollection = null;
      _coursesCollection = null;
      _studentCoursesCollection = null;
    }
  }

  static Future<void> ensureConnected() async {
    if (_isConnecting) {
      print("Connection attempt already in progress, waiting...");
      return;
    }
    if (_db != null && _db!.isConnected) {
      print("MongoDB connection is active");
      return;
    }
    try {
      _isConnecting = true;
      print("Reconnecting to MongoDB...");
      await connect();
    } catch (e) {
      print("Error ensuring MongoDB connection: $e");
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  static Future<void> insertUser(Map<String, dynamic> user) async {
    await ensureConnected();
    if (user['role'] == 'student') {
      user['qrCodeId'] = const Uuid().v4();
    }
    await _usersCollection?.insert(user);
  }

  static Future<Map<String, dynamic>?> findUser(String email, String password) async {
    await ensureConnected();
    final user = await _usersCollection?.findOne(where.eq('email', email).eq('password', password));
    print("Queried user with email: $email, found: $user");
    return user;
  }

  static Future<Map<String, dynamic>?> getUserByRollNumber(String rollNumber) async {
    await ensureConnected();
    return await _usersCollection?.findOne(where.eq('rollNumber', rollNumber));
  }

  static Future<Map<String, dynamic>?> getUserByQrCodeId(String qrCodeId) async {
    await ensureConnected();
    return await _usersCollection?.findOne(where.eq('qrCodeId', qrCodeId));
  }

  static Future<void> updateUserByRollNumber(String rollNumber, Map<String, dynamic> updatedFields) async {
    await ensureConnected();
    await _usersCollection?.update(
      where.eq('rollNumber', rollNumber),
      {'\$set': updatedFields},
    );
  }

  static Future<void> createRequest(Map<String, dynamic> request) async {
    await ensureConnected();
    await _requestsCollection?.insert(request);
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    await ensureConnected();
    final requests = await _requestsCollection?.find(where.eq('status', 'pending')).toList();
    return requests?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> updateRequestStatus(ObjectId requestId, String status) async {
    await ensureConnected();
    await _requestsCollection?.update(
      where.eq('_id', requestId),
      {'\$set': {'status': status}},
    );
  }

  static Future<void> createFeedbackForm(Map<String, dynamic> form) async {
    await ensureConnected();
    await _feedbackFormsCollection?.insert(form);
  }

  static Future<List<Map<String, dynamic>>> getFeedbackFormsByFaculty(String facultyRollNumber) async {
    await ensureConnected();
    final forms = await _feedbackFormsCollection?.find(where.eq('facultyRollNumber', facultyRollNumber)).toList();
    return forms?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getAllFeedbackForms() async {
    await ensureConnected();
    final forms = await _feedbackFormsCollection?.find().toList();
    return forms?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> submitFeedbackResponse(Map<String, dynamic> response) async {
    await ensureConnected();
    await _feedbackResponsesCollection?.insert(response);
  }

  static Future<List<Map<String, dynamic>>> getFeedbackResponsesByFormId(String formId) async {
    await ensureConnected();
    final responses = await _feedbackResponsesCollection?.find(where.eq('formId', formId)).toList();
    return responses?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getAllFeedbackResponses() async {
    await ensureConnected();
    final responses = await _feedbackResponsesCollection?.find().toList();
    return responses?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    await ensureConnected();
    final students = await _usersCollection?.find(where.eq('role', 'student')).toList();
    return students?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> logAccess(Map<String, dynamic> log) async {
    await ensureConnected();
    await _accessLogsCollection?.insert(log);
  }

  static Future<List<Map<String, dynamic>>> getAccessLogs() async {
    await ensureConnected();
    final logs = await _accessLogsCollection?.find().toList();
    return logs?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> logAttendance(Map<String, dynamic> attendance) async {
    await ensureConnected();
    await _accessLogsCollection?.insert(attendance);
  }

  static Future<List<Map<String, dynamic>>> getAttendanceLogsByFaculty(String facultyRollNumber) async {
    await ensureConnected();
    print("faculty roll => " + facultyRollNumber);
    final logs = await _attendanceLogsCollection?.find(where.eq('facultyRollNumber', facultyRollNumber)).toList();
    print(logs);
    return logs?.cast<Map<String, dynamic>>() ?? [];
  }

  // Course-related methods
  static Future<void> createCourse(Map<String, dynamic> course) async {
    await ensureConnected();
    await _coursesCollection?.insert(course);
  }

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    await ensureConnected();
    final courses = await _coursesCollection?.find().toList();
    return courses?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<void> assignCoursesToStudent(String rollNumber, List<String> courseCodes) async {
    await ensureConnected();
    try {
      // Remove any existing course assignments for this student
      print("Removing existing assignments for rollNumber: $rollNumber");
      await _studentCoursesCollection?.remove(where.eq('rollNumber', rollNumber));
      print("Existing assignments removed");

      // Insert new course assignments with a String-based _id
      final assignments = courseCodes.map((courseCode) {
        return {
          '_id': const Uuid().v4(), // Generate a String-based _id
          'rollNumber': rollNumber,
          'courseCode': courseCode.toString(), // Ensure courseCode is a String
          'assignedAt': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (assignments.isNotEmpty) {
        print("Inserting assignments: $assignments");
        await _studentCoursesCollection?.insertAll(assignments);
        print("Courses assigned successfully for rollNumber: $rollNumber");
      } else {
        print("No courses to assign for rollNumber: $rollNumber");
      }
    } catch (e) {
      print("Error assigning courses to student $rollNumber: $e");
      rethrow; // Rethrow to let the caller handle the error
    }
  }

  static Future<List<Map<String, dynamic>>> getCoursesForStudent(String rollNumber) async {
    await ensureConnected();
    try {
      // Get the course codes assigned to the student
      final assignments = await _studentCoursesCollection?.find(where.eq('rollNumber', rollNumber)).toList();
      final courseCodes = assignments?.map((assignment) {
        final courseCode = assignment['courseCode'];
        return courseCode is String ? courseCode : courseCode.toString();
      }).toList() ?? [];

      if (courseCodes.isEmpty) {
        return [];
      }

      // Fetch the course details for the assigned course codes
      final courses = await _coursesCollection?.find(where.oneFrom('courseCode', courseCodes)).toList();
      return courses?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print("Error fetching courses for student $rollNumber: $e");
      return [];
    }
  }
}