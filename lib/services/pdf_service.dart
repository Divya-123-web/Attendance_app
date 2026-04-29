// // pdf_service.dart
// // Generates professional PDF attendance reports.
// //
// // 3 types of reports:
// // 1. Daily Report      → All students for one date (Teacher)
// // 2. Student Report    → One student's full history (Teacher)
// // 3. Department Report → All students summary (HOD)

// import 'dart:io';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/student_model.dart';
// import '../models/attendance_record_model.dart';

// class PdfService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // ═══════════════════════════════════════════════════
//   // 1. DAILY ATTENDANCE REPORT
//   // Shows present + absent students for one date
//   // Called from Teacher Dashboard
//   // ═══════════════════════════════════════════════════
//   Future<File> generateDailyReport({
//     required String date,
//     required List<AttendanceRecord> presentStudents,
//     required List<StudentModel> allStudents,
//     required String teacherName,
//     required String className,
//   }) async {
//     final pdf = pw.Document();

//     // Calculate stats
//     final totalStudents = allStudents.length;
//     final presentCount =
//         presentStudents.where((r) => r.isPresent).length;
//     final absentCount = totalStudents - presentCount;
//     final percentage = totalStudents > 0
//         ? (presentCount / totalStudents * 100).toStringAsFixed(1)
//         : '0.0';

//     // Find absent students
//     final presentRegNos = presentStudents
//         .where((r) => r.isPresent)
//         .map((r) => r.registerNumber)
//         .toSet();
//     final absentStudents = allStudents
//         .where((s) => !presentRegNos.contains(s.registerNumber))
//         .toList();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         header: (context) => _buildHeader(
//           title: 'Daily Attendance Report',
//           subtitle:
//               'Class: $className  |  Date: $date  |  Teacher: $teacherName',
//         ),
//         footer: (context) => _buildFooter(context),
//         build: (context) => [
//           // ── Summary Cards ──
//           _buildSummaryRow(
//             total: totalStudents,
//             present: presentCount,
//             absent: absentCount,
//             percentage: percentage,
//           ),
//           pw.SizedBox(height: 20),

//           // ── Present Table ──
//           _buildSectionTitle('✅  Present Students ($presentCount)'),
//           pw.SizedBox(height: 8),

//           if (presentStudents.isEmpty)
//             _buildEmptyBox('No students marked present yet.')
//           else
//             _buildTable(
//               headers: ['#', 'Reg No', 'Name', 'Time', 'Method'],
//               rows: presentStudents
//                   .where((r) => r.isPresent)
//                   .toList()
//                   .asMap()
//                   .entries
//                   .map((e) => [
//                         '${e.key + 1}',
//                         e.value.registerNumber,
//                         e.value.studentName,
//                         _formatTime(e.value.timestamp),
//                         e.value.manualOverride ? 'Manual' : 'Auto',
//                       ])
//                   .toList(),
//             ),

//           pw.SizedBox(height: 20),

//           // ── Absent Table ──
//           _buildSectionTitle('❌  Absent Students ($absentCount)'),
//           pw.SizedBox(height: 8),

//           if (absentStudents.isEmpty)
//             _buildSuccessBox('🎉 All students are present today!')
//           else
//             _buildTable(
//               headers: ['#', 'Reg No', 'Name', 'Email'],
//               rows: absentStudents
//                   .asMap()
//                   .entries
//                   .map((e) => [
//                         '${e.key + 1}',
//                         e.value.registerNumber,
//                         e.value.name,
//                         e.value.email,
//                       ])
//                   .toList(),
//             ),
//         ],
//       ),
//     );

//     return _savePdf(pdf, 'daily_attendance_$date.pdf');
//   }

//   // ═══════════════════════════════════════════════════
//   // 2. STUDENT HISTORY REPORT
//   // Full attendance history for one student
//   // Called from Student Detail Screen
//   // ═══════════════════════════════════════════════════
//   Future<File> generateStudentReport({
//     required StudentModel student,
//     required List<AttendanceRecord> history,
//   }) async {
//     final pdf = pw.Document();

//     final totalClasses = history.length;
//     final attended = history.where((r) => r.isPresent).length;
//     final missed = totalClasses - attended;
//     final percentage = totalClasses > 0
//         ? (attended / totalClasses * 100).toStringAsFixed(1)
//         : '0.0';

//     // Determine status color
//     final pctValue = double.parse(percentage);
//     final statusText = pctValue >= 75
//         ? 'Good Standing'
//         : pctValue >= 50
//             ? 'At Risk'
//             : 'Poor Attendance';

//     final statusPdfColor = pctValue >= 75
//         ? PdfColors.green700
//         : pctValue >= 50
//             ? PdfColors.orange700
//             : PdfColors.red700;

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         header: (context) => _buildHeader(
//           title: 'Student Attendance Report',
//           subtitle:
//               'Generated on ${_formatDate(DateTime.now())}',
//         ),
//         footer: (context) => _buildFooter(context),
//         build: (context) => [
//           // ── Student Info Card ──
//           pw.Container(
//             padding: const pw.EdgeInsets.all(16),
//             decoration: pw.BoxDecoration(
//               color: PdfColors.indigo50,
//               borderRadius: pw.BorderRadius.circular(10),
//               border: pw.Border.all(color: PdfColors.indigo200),
//             ),
//             child: pw.Row(
//               children: [
//                 pw.Expanded(
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         student.name,
//                         style: pw.TextStyle(
//                           fontSize: 20,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.indigo900,
//                         ),
//                       ),
//                       pw.SizedBox(height: 6),
//                       pw.Text(
//                         'Register No: ${student.registerNumber}',
//                         style: const pw.TextStyle(
//                             color: PdfColors.indigo700),
//                       ),
//                       pw.Text(
//                         'Email: ${student.email}',
//                         style: const pw.TextStyle(
//                             color: PdfColors.indigo700),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Percentage circle badge
//                 pw.Container(
//                   width: 80,
//                   height: 80,
//                   decoration: pw.BoxDecoration(
//                     shape: pw.BoxShape.circle,
//                     color: statusPdfColor,
//                   ),
//                   alignment: pw.Alignment.center,
//                   child: pw.Column(
//                     mainAxisAlignment: pw.MainAxisAlignment.center,
//                     children: [
//                       pw.Text(
//                         '$percentage%',
//                         style: pw.TextStyle(
//                           color: PdfColors.white,
//                           fontSize: 16,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.Text(
//                         statusText,
//                         style: const pw.TextStyle(
//                           color: PdfColors.white,
//                           fontSize: 7,
//                         ),
//                         textAlign: pw.TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           pw.SizedBox(height: 16),

//           // ── Stats ──
//           _buildSummaryRow(
//             total: totalClasses,
//             present: attended,
//             absent: missed,
//             percentage: percentage,
//             totalLabel: 'Total Classes',
//             presentLabel: 'Attended',
//             absentLabel: 'Missed',
//           ),
//           pw.SizedBox(height: 20),

//           // ── History Table ──
//           _buildSectionTitle('📋  Full Attendance History'),
//           pw.SizedBox(height: 8),

//           if (history.isEmpty)
//             _buildEmptyBox('No attendance records found.')
//           else
//             _buildTable(
//               headers: [
//                 '#',
//                 'Date',
//                 'Day',
//                 'Time',
//                 'Status',
//                 'Method'
//               ],
//               rows: history.asMap().entries.map((e) {
//                 final r = e.value;
//                 return [
//                   '${e.key + 1}',
//                   _formatDate(r.timestamp),
//                   _getDayName(r.timestamp),
//                   _formatTime(r.timestamp),
//                   r.isPresent ? 'Present' : 'Absent',
//                   r.manualOverride ? 'Manual' : 'System',
//                 ];
//               }).toList(),
//             ),
//         ],
//       ),
//     );

//     return _savePdf(
//         pdf, 'student_${student.registerNumber}_report.pdf');
//   }

//   // ═══════════════════════════════════════════════════
//   // 3. DEPARTMENT REPORT (HOD)
//   // All students with attendance percentages
//   // Called from HOD Dashboard
//   // ═══════════════════════════════════════════════════
//   Future<File> generateDepartmentReport({
//     required List<StudentModel> allStudents,
//     required String department,
//     required String hodName,
//   }) async {
//     final pdf = pw.Document();

//     // Fetch attendance data for each student from Firestore
//     final List<Map<String, dynamic>> studentStats = [];

//     for (final student in allStudents) {
//       final logs = await _firestore
//           .collection('attendance_logs')
//           .where('registerNumber',
//               isEqualTo: student.registerNumber)
//           .get();

//       final total = logs.docs.length;
//       final present = logs.docs
//           .where((d) => d.data()['isPresent'] == true)
//           .length;
//       final percentage =
//           total > 0 ? (present / total * 100) : 0.0;

//       studentStats.add({
//         'student': student,
//         'total': total,
//         'present': present,
//         'percentage': percentage,
//       });
//     }

//     // Sort worst attendance first
//     studentStats.sort((a, b) => (a['percentage'] as double)
//         .compareTo(b['percentage'] as double));

//     final avgPercentage = studentStats.isEmpty
//         ? 0.0
//         : studentStats
//                 .map((s) => s['percentage'] as double)
//                 .reduce((a, b) => a + b) /
//             studentStats.length;

//     final lowCount = studentStats
//         .where((s) => (s['percentage'] as double) < 75)
//         .length;

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         header: (context) => _buildHeader(
//           title: 'Department Attendance Report',
//           subtitle:
//               'Dept: $department  |  HOD: $hodName  |  ${_formatDate(DateTime.now())}',
//         ),
//         footer: (context) => _buildFooter(context),
//         build: (context) => [
//           // ── Dept Summary ──
//           _buildSummaryRow(
//             total: allStudents.length,
//             present: allStudents.length - lowCount,
//             absent: lowCount,
//             percentage: avgPercentage.toStringAsFixed(1),
//             totalLabel: 'Total Students',
//             presentLabel: 'Above 75%',
//             absentLabel: 'Below 75%',
//           ),
//           pw.SizedBox(height: 20),

//           // ── All Students Table ──
//           _buildSectionTitle(
//               '📊  Department Student Attendance'),
//           pw.SizedBox(height: 8),

//           _buildTable(
//             headers: [
//               '#',
//               'Reg No',
//               'Name',
//               'Classes',
//               'Attended',
//               'Percentage',
//               'Status'
//             ],
//             rows: studentStats.asMap().entries.map((e) {
//               final data = e.value;
//               final student = data['student'] as StudentModel;
//               final pct = data['percentage'] as double;
//               final status = pct >= 75
//                   ? 'Good'
//                   : pct >= 50
//                       ? 'At Risk'
//                       : 'Critical';
//               return [
//                 '${e.key + 1}',
//                 student.registerNumber,
//                 student.name,
//                 '${data['total']}',
//                 '${data['present']}',
//                 '${pct.toStringAsFixed(1)}%',
//                 status,
//               ];
//             }).toList(),
//           ),
//         ],
//       ),
//     );

//     return _savePdf(
//       pdf,
//       'department_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
//     );
//   }

//   // ═══════════════════════════════════════════════════
//   // SHARED WIDGETS
//   // ═══════════════════════════════════════════════════

//   // Header shown on every page top
//   pw.Widget _buildHeader({
//     required String title,
//     required String subtitle,
//   }) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.only(bottom: 12),
//       decoration: const pw.BoxDecoration(
//         border: pw.Border(
//           bottom:
//               pw.BorderSide(color: PdfColors.indigo300, width: 2),
//         ),
//       ),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Text(
//             '🎓 Smart Attendance System',
//             style: pw.TextStyle(
//               fontSize: 10,
//               color: PdfColors.indigo400,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//           pw.SizedBox(height: 4),
//           pw.Text(
//             title,
//             style: pw.TextStyle(
//               fontSize: 18,
//               fontWeight: pw.FontWeight.bold,
//               color: PdfColors.indigo900,
//             ),
//           ),
//           pw.SizedBox(height: 2),
//           pw.Text(
//             subtitle,
//             style: const pw.TextStyle(
//               fontSize: 10,
//               color: PdfColors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Footer shown on every page bottom
//   pw.Widget _buildFooter(pw.Context context) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.only(top: 8),
//       decoration: const pw.BoxDecoration(
//         border: pw.Border(
//           top: pw.BorderSide(color: PdfColors.grey300, width: 1),
//         ),
//       ),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(
//             'Smart Attendance System — Confidential',
//             style: const pw.TextStyle(
//                 fontSize: 9, color: PdfColors.grey),
//           ),
//           pw.Text(
//             'Page ${context.pageNumber} of ${context.pagesCount}',
//             style: const pw.TextStyle(
//                 fontSize: 9, color: PdfColors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   // 4 colored summary boxes in a row
//   pw.Widget _buildSummaryRow({
//     required int total,
//     required int present,
//     required int absent,
//     required String percentage,
//     String totalLabel = 'Total',
//     String presentLabel = 'Present',
//     String absentLabel = 'Absent',
//   }) {
//     return pw.Row(
//       children: [
//         _summaryBox(totalLabel, '$total', PdfColors.indigo600),
//         pw.SizedBox(width: 8),
//         _summaryBox(presentLabel, '$present', PdfColors.green600),
//         pw.SizedBox(width: 8),
//         _summaryBox(absentLabel, '$absent', PdfColors.red600),
//         pw.SizedBox(width: 8),
//         _summaryBox('Rate', '$percentage%', PdfColors.orange600),
//       ],
//     );
//   }

//   pw.Widget _summaryBox(
//       String label, String value, PdfColor color) {
//     return pw.Expanded(
//       child: pw.Container(
//         padding: const pw.EdgeInsets.symmetric(vertical: 14),
//         decoration: pw.BoxDecoration(
//           color: color,
//           borderRadius: pw.BorderRadius.circular(8),
//         ),
//         child: pw.Column(
//           children: [
//             pw.Text(
//               value,
//               style: pw.TextStyle(
//                 color: PdfColors.white,
//                 fontSize: 20,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(height: 4),
//             pw.Text(
//               label,
//               style: const pw.TextStyle(
//                 color: PdfColors.white,
//                 fontSize: 9,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Purple section title bar
//   pw.Widget _buildSectionTitle(String title) {
//     return pw.Container(
//       width: double.infinity,
//       padding:
//           const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.indigo600,
//         borderRadius: pw.BorderRadius.circular(6),
//       ),
//       child: pw.Text(
//         title,
//         style: pw.TextStyle(
//           color: PdfColors.white,
//           fontWeight: pw.FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   // Data table with headers and rows
//   pw.Widget _buildTable({
//     required List<String> headers,
//     required List<List<String>> rows,
//   }) {
//     return pw.Table(
//       border: pw.TableBorder.all(
//         color: PdfColors.grey300,
//         width: 0.5,
//       ),
//       children: [
//         // Header row — dark purple background
//         pw.TableRow(
//           decoration: const pw.BoxDecoration(
//             color: PdfColors.indigo700,
//           ),
//           children: headers
//               .map(
//                 (h) => pw.Padding(
//                   padding: const pw.EdgeInsets.all(8),
//                   child: pw.Text(
//                     h,
//                     style: pw.TextStyle(
//                       color: PdfColors.white,
//                       fontWeight: pw.FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//         ),

//         // Data rows — alternating white/grey
//         ...rows.asMap().entries.map((entry) {
//           final isEven = entry.key % 2 == 0;
//           final cells = entry.value;

//           return pw.TableRow(
//             decoration: pw.BoxDecoration(
//               color: isEven ? PdfColors.white : PdfColors.grey100,
//             ),
//             children: cells.asMap().entries.map((cell) {
//               // Color status column automatically
//               PdfColor textColor = PdfColors.grey800;
//               final val = cell.value;

//               if (val == 'Present' || val == 'Good' || val == 'Auto') {
//                 textColor = PdfColors.green700;
//               } else if (val == 'Absent' ||
//                   val == 'Critical' ||
//                   val == 'Manual') {
//                 textColor = PdfColors.red700;
//               } else if (val == 'At Risk') {
//                 textColor = PdfColors.orange700;
//               }

//               return pw.Padding(
//                 padding: const pw.EdgeInsets.all(7),
//                 child: pw.Text(
//                   val,
//                   style: pw.TextStyle(
//                     fontSize: 9,
//                     color: textColor,
//                   ),
//                 ),
//               );
//             }).toList(),
//           );
//         }),
//       ],
//     );
//   }

//   // Empty state box
//   pw.Widget _buildEmptyBox(String message) {
//     return pw.Container(
//       width: double.infinity,
//       padding: const pw.EdgeInsets.all(16),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.grey100,
//         borderRadius: pw.BorderRadius.circular(8),
//         border: pw.Border.all(color: PdfColors.grey300),
//       ),
//       child: pw.Text(
//         message,
//         style: const pw.TextStyle(color: PdfColors.grey),
//         textAlign: pw.TextAlign.center,
//       ),
//     );
//   }

//   // Success state box (green)
//   pw.Widget _buildSuccessBox(String message) {
//     return pw.Container(
//       width: double.infinity,
//       padding: const pw.EdgeInsets.all(16),
//       decoration: pw.BoxDecoration(
//         color: PdfColors.green50,
//         borderRadius: pw.BorderRadius.circular(8),
//         border: pw.Border.all(color: PdfColors.green200),
//       ),
//       child: pw.Text(
//         message,
//         style: pw.TextStyle(
//           color: PdfColors.green700,
//           fontWeight: pw.FontWeight.bold,
//         ),
//         textAlign: pw.TextAlign.center,
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════
//   // SAVE + SHARE + PREVIEW
//   // ═══════════════════════════════════════════════════

//   // Save PDF file to temp directory
//   Future<File> _savePdf(pw.Document pdf, String filename) async {
//     final output = await getTemporaryDirectory();
//     final file = File('${output.path}/$filename');
//     await file.writeAsBytes(await pdf.save());
//     print('✅ PDF saved: ${file.path}');
//     return file;
//   }

//   // Preview PDF inside the app
//   Future<void> previewPdf(File pdfFile) async {
//     await Printing.layoutPdf(
//       onLayout: (format) async => pdfFile.readAsBytesSync(),
//     );
//   }

//   // Share PDF via WhatsApp, Email, Drive etc.
//   Future<void> sharePdf(File pdfFile, String reportName) async {
//     await Share.shareXFiles(
//       [XFile(pdfFile.path)],
//       text: 'Attendance Report — $reportName',
//       subject: 'Smart Attendance Report',
//     );
//   }

//   // ═══════════════════════════════════════════════════
//   // DATE/TIME HELPERS
//   // ═══════════════════════════════════════════════════

//   String _formatDate(DateTime dt) =>
//       '${dt.day.toString().padLeft(2, '0')}/'
//       '${dt.month.toString().padLeft(2, '0')}/'
//       '${dt.year}';

//   String _formatTime(DateTime dt) {
//     final hour = dt.hour;
//     final minute = dt.minute.toString().padLeft(2, '0');
//     final period = hour < 12 ? 'AM' : 'PM';
//     final displayHour = hour == 0
//         ? 12
//         : hour > 12
//             ? hour - 12
//             : hour;
//     return '$displayHour:$minute $period';
//   }

//   String _getDayName(DateTime dt) {
//     const days = [
//       'Monday',
//       'Tuesday',
//       'Wednesday',
//       'Thursday',
//       'Friday',
//       'Saturday',
//       'Sunday'
//     ];
//     return days[dt.weekday - 1];
//   }
// }