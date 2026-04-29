// // data_entry_screen.dart
// // Screen for entering user data from json_data.dart
// // Allows picking image from mobile, saves to Firebase users collection

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:google_mlkit_commons/google_mlkit_commons.dart';
// import 'package:provider/provider.dart';
// import '../models/user_model.dart';
// import '../provider/data_entry_provider.dart';

// class DataEntryScreen extends StatefulWidget {
//   const DataEntryScreen({super.key});

//   @override
//   State<DataEntryScreen> createState() => _DataEntryScreenState();
// }

// class _DataEntryScreenState extends State<DataEntryScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _picker = ImagePicker();
//   final _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableContours: false,
//       enableClassification: true,
//       enableLandmarks: false,
//       enableTracking: false,
//       minFaceSize: 0.1,
//       performanceMode: FaceDetectorMode.fast,
//     ),
//   );

//   // Form controllers
//   final _timestampController = TextEditingController(text: DateTime.now().toString());
//   final _nameController = TextEditingController();
//   final _registerNumberController = TextEditingController();
//   final _emailIdController = TextEditingController();
//   final _departmentController = TextEditingController();
//   final _yearController = TextEditingController();
//   final _secController = TextEditingController();
//   final _phoneNumberController = TextEditingController();
//   final _emailAddressController = TextEditingController();
//   final _column9Controller = TextEditingController();

//   @override
//   void dispose() {
//     _timestampController.dispose();
//     _nameController.dispose();
//     _registerNumberController.dispose();
//     _emailIdController.dispose();
//     _departmentController.dispose();
//     _yearController.dispose();
//     _secController.dispose();
//     _phoneNumberController.dispose();
//     _emailAddressController.dispose();
//     _column9Controller.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     final provider = context.read<DataEntryProvider>();

//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Take Photo'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final pickedFile = await _picker.pickImage(source: ImageSource.camera);
//                 if (pickedFile != null) {
//                   provider.setSelectedImage(File(pickedFile.path));
//                 }
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Choose from Gallery'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//                 if (pickedFile != null) {
//                   provider.setSelectedImage(File(pickedFile.path));
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _captureFace() async {
//     final provider = context.read<DataEntryProvider>();

//     try {
//       // Capture image from camera
//       final pickedFile = await _picker.pickImage(source: ImageSource.camera);
//       if (pickedFile == null) return;

//       final imageFile = File(pickedFile.path);

//       // Detect faces
//       final inputImage = InputImage.fromFile(imageFile);
//       final faces = await _faceDetector.processImage(inputImage);

//       if (faces.isEmpty) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('No face detected. Please try again.')),
//           );
//         }
//         return;
//       }

//       if (faces.length > 1) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Multiple faces detected. Please ensure only one face is visible.')),
//           );
//         }
//         return;
//       }

//       final face = faces.first;

//       // Validate face quality
//       final hasLeftEyeOpen = face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! > 0.5;
//       final hasRightEyeOpen = face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! > 0.5;

//       if (!hasLeftEyeOpen || !hasRightEyeOpen) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please keep both eyes open for better recognition.')),
//           );
//         }
//         return;
//       }

//       // Face is valid, set it
//       provider.setSelectedFaceImage(imageFile);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Face captured successfully!')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Face capture failed: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _saveUser() async {
//     if (!_formKey.currentState!.validate()) return;

//     final provider = context.read<DataEntryProvider>();

//     // Check if image is selected
//     if (provider.selectedImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a passport size photo')),
//       );
//       return;
//     }

//     final user = UserModel(
//       timestamp: _timestampController.text,
//       name: _nameController.text,
//       registerNumber: int.parse(_registerNumberController.text),
//       emailId: _emailIdController.text,
//       department: _departmentController.text,
//       year: _yearController.text,
//       sec: _secController.text,
//       phoneNumber: int.parse(_phoneNumberController.text),
//       passportSizePhoto: '', // Will be replaced with storage URL
//       emailAddress: _emailAddressController.text,
//       column9: _column9Controller.text,
//     );

//     final success = await provider.saveUser(user);
//     if (success && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User saved successfully!')),
//       );
//     }
//   }

//   void _nextUser() {
//     final provider = context.read<DataEntryProvider>();
//     provider.clearForm();

//     // Clear form fields
//     _nameController.clear();
//     _registerNumberController.clear();
//     _emailIdController.clear();
//     _departmentController.clear();
//     _yearController.clear();
//     _secController.clear();
//     _phoneNumberController.clear();
//     _emailAddressController.clear();
//     _column9Controller.clear();

//     // Reset timestamp to current
//     _timestampController.text = DateTime.now().toString();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Form cleared for next user')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<DataEntryProvider>(
//       builder: (context, provider, child) {
//         return Scaffold(
//           backgroundColor: const Color(0xFF1A1A2E),
//           appBar: AppBar(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             title: const Text(
//               'Data Entry',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//           body: SafeArea(
//             child: Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Image picker section
//                     const Text(
//                       'Passport Size Photo',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     GestureDetector(
//                       onTap: _pickImage,
//                       child: Container(
//                         width: double.infinity,
//                         height: 200,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF16213E),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: provider.selectedImage != null
//                                 ? Colors.green
//                                 : Colors.white24,
//                           ),
//                         ),
//                         child: provider.selectedImage != null
//                             ? ClipRRect(
//                                 borderRadius: BorderRadius.circular(16),
//                                 child: Image.file(
//                                   provider.selectedImage!,
//                                   fit: BoxFit.cover,
//                                 ),
//                               )
//                             : const Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.add_a_photo,
//                                     color: Colors.white54,
//                                     size: 48,
//                                   ),
//                                   SizedBox(height: 8),
//                                   Text(
//                                     'Tap to select image',
//                                     style: TextStyle(color: Colors.white54),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Form fields
//                     _buildTextField('Timestamp', _timestampController, readOnly: true),
//                     _buildTextField('Name', _nameController, validator: (value) {
//                       if (value?.isEmpty ?? true) return 'Name is required';
//                       return null;
//                     }),
//                     _buildTextField('Register Number', _registerNumberController,
//                         keyboardType: TextInputType.number, validator: (value) {
//                       if (value?.isEmpty ?? true) return 'Register number is required';
//                       if (int.tryParse(value!) == null) return 'Invalid number';
//                       return null;
//                     }),
//                     _buildTextField('Email-ID', _emailIdController, validator: (value) {
//                       if (value?.isEmpty ?? true) return 'Email is required';
//                       if (!value!.contains('@')) return 'Invalid email';
//                       return null;
//                     }),
//                     _buildTextField('Department', _departmentController),
//                     _buildTextField('Year', _yearController),
//                     _buildTextField('Section', _secController),
//                     _buildTextField('Phone Number', _phoneNumberController,
//                         keyboardType: TextInputType.phone, validator: (value) {
//                       if (value?.isEmpty ?? true) return 'Phone number is required';
//                       if (int.tryParse(value!) == null) return 'Invalid number';
//                       return null;
//                     }),
//                     _buildTextField('Email Address', _emailAddressController),
//                     _buildTextField('Notes', _column9Controller),

//                     const SizedBox(height: 24),

//                     // Error message
//                     if (provider.errorMessage.isNotEmpty) ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.red.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: Colors.red.shade400),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.error, color: Colors.red, size: 18),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 provider.errorMessage,
//                                 style: const TextStyle(color: Colors.red, fontSize: 13),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                     ],

//                     // Buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: provider.isSaving ? null : _saveUser,
//                             icon: provider.isSaving
//                                 ? const SizedBox(
//                                     width: 20, height: 20,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white, strokeWidth: 2,
//                                     ),
//                                   )
//                                 : const Icon(Icons.save),
//                             label: Text(
//                               provider.isSaving ? 'Saving...' : 'Save User',
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF6C63FF),
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         ElevatedButton.icon(
//                           onPressed: _nextUser,
//                           icon: const Icon(Icons.next_plan),
//                           label: const Text('Next'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF3ECFCF),
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 24, vertical: 16,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller,
//       {TextInputType? keyboardType, bool readOnly = false, String? Function(String?)? validator}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         readOnly: readOnly,
//         validator: validator,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.white70),
//           filled: true,
//           fillColor: const Color(0xFF16213E),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.white24),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Color(0xFF6C63FF)),
//           ),
//         ),
//       ),
//     );
//   }
// }