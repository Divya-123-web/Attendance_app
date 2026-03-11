// email_service.dart
// Sends automated email report to teacher when attendance is marked.
// Uses the 'mailer' package with SMTP (Gmail).
//
// SETUP REQUIRED:
// 1. Use a Gmail account
// 2. Enable 2-Step Verification
// 3. Generate an App Password at: myaccount.google.com/apppasswords
// 4. Use that 16-char App Password below (NOT your real Gmail password)

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:attendanceapp/models/student_models.dart';

class EmailService {
  // ⚠️ REPLACE THESE WITH YOUR ACTUAL CREDENTIALS
  static const String _senderEmail = 'your_gmail@gmail.com';
  static const String _appPassword = 'your_app_password_here'; // 16-char App Password
  static const String _teacherEmail = 'teacher@school.edu';

  // ─────────────────────────────────────────
  // SEND ATTENDANCE REPORT TO TEACHER
  // ─────────────────────────────────────────
  Future<void> sendAttendanceReport(StudentModel student) async {
    try {
      // Configure Gmail SMTP server
      // gmail() is a pre-configured SMTP helper for Gmail
      final smtpServer = gmail(_senderEmail, _appPassword);

      // Build the email HTML body
      final htmlBody = _buildEmailHtml(student);

      // Create the Message object
      final message = Message()
        ..from = Address(_senderEmail, 'Smart Attendance System')
        ..recipients.add(_teacherEmail)     // Teacher's email
        ..subject = '✅ Attendance Marked — ${student.name} (${student.registerNumber})'
        ..html = htmlBody;                  // HTML formatted email

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent: ${sendReport.toString()}');

    } on MailerException catch (e) {
      // MailerException gives detailed SMTP error info
      print('❌ Email failed: ${e.message}');
      throw Exception('Email sending failed: ${e.message}');
    }
  }

  // ─────────────────────────────────────────
  // BUILD FORMATTED HTML EMAIL BODY
  // ─────────────────────────────────────────
  String _buildEmailHtml(StudentModel student) {
    final time = student.attendanceTime != null
        ? '${student.attendanceTime!.hour}:${student.attendanceTime!.minute.toString().padLeft(2, '0')}'
        : 'N/A';
    final date = student.attendanceTime != null
        ? '${student.attendanceTime!.day}/${student.attendanceTime!.month}/${student.attendanceTime!.year}'
        : 'N/A';

    return '''
    <html>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: #4CAF50; padding: 20px; border-radius: 8px 8px 0 0;">
        <h1 style="color: white; margin: 0;">✅ Attendance Confirmed</h1>
      </div>
      <div style="background: #f9f9f9; padding: 20px; border: 1px solid #ddd;">
        <h2 style="color: #333;">Student Details</h2>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 10px; font-weight: bold; color: #555;">Name:</td>
            <td style="padding: 10px;">${student.name}</td>
          </tr>
          <tr style="background: #fff;">
            <td style="padding: 10px; font-weight: bold; color: #555;">Register No:</td>
            <td style="padding: 10px;">${student.registerNumber}</td>
          </tr>
          <tr>
            <td style="padding: 10px; font-weight: bold; color: #555;">Email:</td>
            <td style="padding: 10px;">${student.email}</td>
          </tr>
          <tr style="background: #fff;">
            <td style="padding: 10px; font-weight: bold; color: #555;">Date:</td>
            <td style="padding: 10px;">$date</td>
          </tr>
          <tr>
            <td style="padding: 10px; font-weight: bold; color: #555;">Time:</td>
            <td style="padding: 10px;">$time</td>
          </tr>
        </table>
        <div style="margin-top: 20px; padding: 15px; background: #e8f5e9; border-radius: 5px;">
          <p style="margin: 0; color: #2e7d32;">
            ✔ Face Recognition: <strong>Verified</strong><br>
            ✔ Location Verification: <strong>Inside Classroom</strong>
          </p>
        </div>
      </div>
      <div style="background: #eee; padding: 10px; text-align: center; font-size: 12px; color: #888;">
        Sent automatically by Smart Attendance System
      </div>
    </body>
    </html>
    ''';
  }
}