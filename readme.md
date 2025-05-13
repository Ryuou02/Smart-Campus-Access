# Smart Campus Access

## Overview

**Smart Campus Access** is a Flutter-based mobile application designed to streamline campus management for students, faculty, admins, and security staff. It provides a centralized platform for managing student profiles, assigning courses, submitting feedback, and generating QR code-based ID cards for secure access.

The application integrates with **MongoDB Atlas** for data storage, ensuring scalability and reliability. This project was developed as part of a university management system, focusing on a user-friendly interface and efficient backend operations.

---

## Features

### 👤 **User Roles**

- **Students**
  - View and edit profile
  - Access assigned courses with resource links
  - Submit feedback
  - View QR code-based ID card for secure access

- **Admins**
  - Manage student profiles
  - Assign courses
  - Approve/reject profile update requests
  - View access and attendance logs
  - View all feedback

- **Faculty**
  - Create feedback forms with custom questions
  - View attendance logs

- **Security**
  - Scan QR codes to mark entry/exit
  - Log and track student access data

---

### 📚 **Course Management**

- Admins can assign courses to students.
- Students can view course details (name, code, resource links).


### 🆔 **QR Code ID Cards**

- Each student has a QR code-based ID card.
- ID displays student details for quick scan-based verification.

### 🧾 **Profile Management**

- Students submit profile update requests.
- Admins review and approve/reject them.

### 📊 **Access and Attendance Logs**

- Logs student and faculty entries.
- Security scans QR codes.
- Admins review complete logs.

---

## 🛠 Technologies Used

- **Frontend**: Flutter (Dart)
- **Backend**: MongoDB Atlas (via `mongo_dart` package)
- **QR Code**: Integrated for student ID cards
- **URL Handling**: `url_launcher` for clickable course resources
- **State Management**: Stateful widgets
- **Tested Platform**: Android (extendable to iOS)

---

## ✅ Prerequisites

Make sure the following tools are installed:

- [Flutter SDK](https://flutter.dev) (v3.0.0 or higher)
- Dart (included with Flutter)
- MongoDB Atlas account
- Android Studio or VS Code
- Android emulator or device

---

## 🚀 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/smart-campus-access.git
cd smart-campus-access
```

## License

This project is proprietary and confidential. All rights reserved © 2025.  
See [LICENSE.md](./LICENSE.md) for full terms and contributors.
