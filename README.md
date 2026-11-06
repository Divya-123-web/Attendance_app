Smart Attendance System 📚

Project Overview

Smart Attendance System is a Flutter-based mobile application that automates student attendance using face registration and classroom location verification.

The application allows students to register their details, complete face registration, and verify their classroom location before attendance is marked. Teachers can monitor student attendance through a dashboard, while HODs have a separate department-level access portal.

✨ Key Features

1. Role-Based Access

- Student Portal – Mark attendance.
- Teacher Portal – View and manage attendance.
- HOD Portal – Department-level access.

2. Student Registration

- Full Name
- Register Number
- Email Address
- Student information storage.

3. Face Registration

- Face image capture / selection.
- Face detection and registration.
- Face verification as part of the attendance process.

4. Location Verification

- GPS-based location tracking.
- Classroom geofencing.
- Distance calculation between student and classroom.
- Attendance eligibility based on classroom boundary.

5. Attendance Management

- Automatic attendance processing.
- Present and Absent status.
- Attendance date and time.
- Teacher can search students by name or register number.
- Filter attendance by All, Present and Absent.

6. Teacher Dashboard

- Attendance overview.
- Daily attendance records.
- Student attendance management.
- Attendance statistics.

7. HOD Portal

- Separate HOD login.
- Department-level access.

8. Email Notification

- Email report notification functionality.
- SMTP authentication configuration required for successful email delivery.

🛠️ Technologies Used

Technology| Purpose
Flutter| Mobile application development
Dart| Programming language
Firebase Firestore| Student and attendance data
Firebase Storage| Face image storage
Google ML Kit| Face detection
Image Picker| Image selection
Geolocator| GPS location tracking
Geofencing| Classroom boundary verification

📱 Application Workflow

1. Student selects the Student Portal.
2. Enters registration details.
3. Completes face registration.
4. System verifies classroom location.
5. Attendance is marked according to the verification result.
6. Attendance information is stored.
7. Teachers view student attendance through the dashboard.

🎯 Project Objective

The main objective is to reduce manual attendance work, prevent proxy attendance, and improve attendance accuracy through biometric and location-based verification.

🔮 Future Enhancements

- Improve face recognition accuracy.
- Add anti-spoofing verification.
- Implement push notifications.
- Improve attendance analytics.
- Enhance department-level reporting.

👩‍💻 Developer

J. Divya Dharshini

Flutter Mobile App Developer

Project Type: Final Year Academic Project
Platform: Android
Framework: Flutter
