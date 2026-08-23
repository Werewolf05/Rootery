import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';  // Removed for build compatibility
// import 'dart:io';
import '../theme/rootery_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _subjectController = TextEditingController();
  int _rating = 0;
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';
  // List<XFile> _selectedImages = [];  // Removed
  List<String> _selectedImages = []; // Placeholder
  // final ImagePicker _picker = ImagePicker();  // Removed

  @override
  void dispose() {
    _feedbackController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage(ImageSource source) async {  // Removed
  // ignore: unused_element
  Future<void> _pickImage() async {
    // Image picker removed for build compatibility
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image attachment feature coming soon'),
        backgroundColor: RooteryTheme.warning,
      ),
    );
  }

  // ignore: unused_element
  Future<void> _pickMultipleImages() async {
    // Image picker removed for build compatibility
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image attachment feature coming soon'),
        backgroundColor: RooteryTheme.warning,
      ),
    );
  }

  // ignore: unused_element
  void _removeImage(int index) {
    // Image picker removed
  }

  void _showImageSourceDialog() {
    // Image picker removed - show info instead
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image attachment feature coming soon'),
        backgroundColor: RooteryTheme.info,
      ),
    );
  }

  bool get _isComplaint =>
      _selectedCategory == 'Complaint' || _selectedCategory == 'Bug';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Feedback & Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Help Us Improve',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share feedback, report issues, or raise complaints with photo evidence',
              style: TextStyle(color: RooteryTheme.subText, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(
              'Feedback Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: RooteryTheme.card,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                dropdownColor: RooteryTheme.card,
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: 'General',
                    child: Row(
                      children: [
                        Icon(Icons.feedback, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('General Feedback'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Complaint',
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Raise a Complaint'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Bug',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Report a Bug'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Feature',
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                        SizedBox(width: 8),
                        Text('Feature Request'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Support',
                    child: Row(
                      children: [
                        Icon(Icons.help, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Technical Support'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Row(
                      children: [
                        Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Other'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Priority (show for complaints and bugs)
            if (_isComplaint) ...[
              Text(
                'Priority Level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildPriorityChip('Low', Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPriorityChip('Medium', Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPriorityChip('High', Colors.red)),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Subject (for complaints)
            if (_isComplaint) ...[
              Text(
                'Subject',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Brief subject line for your complaint',
                  hintStyle: TextStyle(color: RooteryTheme.subText),
                  filled: true,
                  fillColor: RooteryTheme.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: RooteryTheme.accentGreen),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: RooteryTheme.accentGreen,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: RooteryTheme.accentGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Rating Section (only for feedback)
            if (!_isComplaint) ...[
              Text(
                'Rate Your Experience',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _rating = index + 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.star,
                          size: 36,
                          color: _rating > index
                              ? RooteryTheme.accentGreen
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Feedback/Complaint Text
            Text(
              _isComplaint ? 'Complaint Details' : 'Your Feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isComplaint
                    ? 'Describe your complaint in detail...'
                    : 'Tell us what you think...',
                hintStyle: TextStyle(color: RooteryTheme.subText),
                filled: true,
                fillColor: RooteryTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: RooteryTheme.accentGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: RooteryTheme.accentGreen,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: RooteryTheme.accentGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Upload Section
            Text(
              'Attach Photos (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isComplaint
                  ? 'Add photos to help us understand your complaint better'
                  : 'Add screenshots or photos to support your feedback',
              style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Image Preview Grid
            // Image attachments removed for build compatibility
            /*if (_selectedImages.isNotEmpty) ...[
              Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: RooteryTheme.accentGreen,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ], */

            // Add Photo Button
            OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(
                _selectedImages.isEmpty ? 'Add Photos' : 'Add More Photos',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: RooteryTheme.accentGreen,
                side: BorderSide(color: RooteryTheme.accentGreen),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RooteryTheme.accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (_feedbackController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isComplaint
                              ? 'Please enter complaint details'
                              : 'Please enter your feedback',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  if (_isComplaint && _subjectController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a subject for your complaint',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // Here you would typically upload images and send data to backend
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isComplaint
                            ? 'Complaint submitted successfully! Reference ID: #${DateTime.now().millisecondsSinceEpoch}'
                            : 'Thank you for your feedback!',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  // Clear form
                  _feedbackController.clear();
                  _subjectController.clear();
                  setState(() {
                    _rating = 0;
                    // _selectedImages.clear();  // Removed
                  });
                },
                child: Text(
                  _isComplaint ? 'Submit Complaint' : 'Submit Feedback',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Box for Complaints
            if (_isComplaint)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade300,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your complaint will be reviewed within 24-48 hours. You\'ll receive a reference ID for tracking.',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Contact Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RooteryTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RooteryTheme.accentGreen, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Immediate Assistance?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: RooteryTheme.subText, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'support@rootery.com',
                        style: TextStyle(color: RooteryTheme.subText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, color: RooteryTheme.subText, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '+91-XXX-XXX-XXXX',
                        style: TextStyle(color: RooteryTheme.subText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: RooteryTheme.subText,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mon-Sat: 9:00 AM - 6:00 PM',
                        style: TextStyle(color: RooteryTheme.subText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, Color color) {
    final isSelected = _selectedPriority == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : RooteryTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade400,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

