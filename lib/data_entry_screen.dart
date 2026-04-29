// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import '../models/user_model.dart';
// import '../provider/data_entry_provider.dart';
// import '../json_data.dart';

// // ─── Screen ──────────────────────────────────────────────────────────────────

// class DataInputScreen extends StatefulWidget {
//   const DataInputScreen({super.key});

//   @override
//   State<DataInputScreen> createState() => _DataInputScreenState();
// }

// class _DataInputScreenState extends State<DataInputScreen>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
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

//   final _picker = ImagePicker();
//   int _currentIndex = 0;

//   late AnimationController _animCtrl;
//   late Animation<double> _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _animCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 600));
//     _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
//     _animCtrl.forward();
//     _loadCurrentData();
//   }

//   @override
//   void dispose() {
//     _animCtrl.dispose();
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

//   void _loadCurrentData() {
//     if (_currentIndex < data.length) {
//       final entry = data[_currentIndex];
//       _timestampController.text = entry['Timestamp'] ?? '';
//       _nameController.text = entry['Name'] ?? '';
//       _registerNumberController.text = entry['Register number']?.toString() ?? '';
//       _emailIdController.text = entry['Email-ID'] ?? '';
//       _departmentController.text = entry['Department'] ?? '';
//       _yearController.text = entry['Year'] ?? '';
//       _secController.text = entry['Sec'] ?? '';
//       _phoneNumberController.text = entry['Phone Number']?.toString() ?? '';
//       _emailAddressController.text = entry['Email address'] ?? '';
//       _column9Controller.text = entry['Column 9'] ?? '';
//     }
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     final provider = context.read<DataEntryProvider>();

//     final pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
//     if (pickedFile != null) {
//       provider.setSelectedImage(File(pickedFile.path));
//     }
//   }

//   void _showImageSourceSheet() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (_) => SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2)),
//               ),
//               const SizedBox(height: 16),
//               const Text('Select Image',
//                   style: TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.w600)),
//               const SizedBox(height: 12),
//               ListTile(
//                 leading: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                       color: const Color(0xFF6C5CE7).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10)),
//                   child: const Icon(Icons.photo_library_rounded,
//                       color: Color(0xFF6C5CE7)),
//                 ),
//                 title: const Text('Choose from Gallery'),
//                 subtitle: const Text('Browse your photo library'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImage(ImageSource.gallery);
//                 },
//               ),
//               ListTile(
//                 leading: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                       color: const Color(0xFF00B894).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10)),
//                   child: const Icon(Icons.camera_alt_rounded,
//                       color: Color(0xFF00B894)),
//                 ),
//                 title: const Text('Take Photo'),
//                 subtitle: const Text('Capture with camera'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImage(ImageSource.camera);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _saveRecord() async {
//     if (!_formKey.currentState!.validate()) return;

//     final provider = context.read<DataEntryProvider>();

//     // Image is now optional - warn if not selected
//     if (provider.selectedImage == null) {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           backgroundColor: const Color(0xFF1A1A2E),
//           title: const Text('No Image Selected', style: TextStyle(color: Colors.white)),
//           content: const Text(
//             'Save without passport photo? You can add it later.',
//             style: TextStyle(color: Colors.white70),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Save Without Image', style: TextStyle(color: Color(0xFF6C63FF))),
//             ),
//           ],
//         ),
//       );
//       if (confirmed != true) return;
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
//         SnackBar(content: Text('${user.name} saved successfully!')),
//       );
//       // Move to next user after saving
//       _nextUser();
//     }
//   }

//   void _nextUser() {
//     final provider = context.read<DataEntryProvider>();
//     provider.clearForm();

//     // Move to next data entry
//     if (_currentIndex < data.length - 1) {
//       _currentIndex++;
//       _loadCurrentData();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Loaded data for user ${_currentIndex + 1} of ${data.length}')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('All users processed!')),
//       );
//     }
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
//             title: Text(
//               'Data Entry (${_currentIndex + 1}/${data.length})',
//               style: const TextStyle(color: Colors.white),
//             ),
//             actions: [
//               if (provider.state == DataEntryState.success)
//                 IconButton(
//                   onPressed: _nextUser,
//                   icon: const Icon(Icons.next_plan, color: Colors.white),
//                   tooltip: 'Next user',
//                 ),
//             ],
//           ),
//           body: FadeTransition(
//             opacity: _fadeAnim,
//             child: SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Image picker section
//                       const Text(
//                         'Passport Size Photo',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       GestureDetector(
//                         onTap: _showImageSourceSheet,
//                         child: Container(
//                           width: double.infinity,
//                           height: 200,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF16213E),
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(
//                               color: provider.selectedImage != null
//                                   ? Colors.green
//                                   : Colors.white24,
//                             ),
//                           ),
//                           child: provider.selectedImage != null
//                               ? ClipRRect(
//                                   borderRadius: BorderRadius.circular(16),
//                                   child: Image.file(
//                                     provider.selectedImage!,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 )
//                               : const Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.add_a_photo,
//                                       color: Colors.white54,
//                                       size: 48,
//                                     ),
//                                     SizedBox(height: 8),
//                                     Text(
//                                       'Tap to select image',
//                                       style: TextStyle(color: Colors.white54),
//                                     ),
//                                   ],
//                                 ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Form fields
//                       _buildTextField('Timestamp', _timestampController, readOnly: true),
//                       _buildTextField('Name', _nameController, validator: (value) {
//                         if (value?.isEmpty ?? true) return 'Name is required';
//                         return null;
//                       }),
//                       _buildTextField('Register Number', _registerNumberController,
//                           keyboardType: TextInputType.number, validator: (value) {
//                         if (value?.isEmpty ?? true) return 'Register number is required';
//                         if (int.tryParse(value!) == null) return 'Invalid number';
//                         return null;
//                       }),
//                       _buildTextField('Email-ID', _emailIdController, validator: (value) {
//                         if (value?.isEmpty ?? true) return 'Email is required';
//                         if (!value!.contains('@')) return 'Invalid email';
//                         return null;
//                       }),
//                       _buildTextField('Department', _departmentController),
//                       _buildTextField('Year', _yearController),
//                       _buildTextField('Section', _secController),
//                       _buildTextField('Phone Number', _phoneNumberController,
//                           keyboardType: TextInputType.phone, validator: (value) {
//                         if (value?.isEmpty ?? true) return 'Phone number is required';
//                         if (int.tryParse(value!) == null) return 'Invalid number';
//                         return null;
//                       }),
//                       _buildTextField('Email Address', _emailAddressController),
//                       _buildTextField('Notes', _column9Controller),

//                       const SizedBox(height: 24),

//                       // Error message
//                       if (provider.errorMessage.isNotEmpty) ...[
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.red.withOpacity(0.15),
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: Colors.red.shade400),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.error, color: Colors.red, size: 18),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   provider.errorMessage,
//                                   style: const TextStyle(color: Colors.red, fontSize: 13),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                       ],

//                       // Buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: provider.isSaving ? null : _saveRecord,
//                               icon: provider.isSaving
//                                   ? const SizedBox(
//                                       width: 20, height: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white, strokeWidth: 2,
//                                       ),
//                                     )
//                                   : const Icon(Icons.save),
//                               label: Text(
//                                 provider.isSaving ? 'Saving...' : 'Save User',
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF6C63FF),
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           ElevatedButton.icon(
//                             onPressed: _nextUser,
//                             icon: const Icon(Icons.next_plan),
//                             label: const Text('Next'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF3ECFCF),
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24, vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
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