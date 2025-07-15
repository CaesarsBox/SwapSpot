import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class PostTab extends StatefulWidget {
  const PostTab({super.key});

  @override
  State<PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<PostTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  String _condition = 'Good';
  String _location = 'Nairobi';

  bool _isSubmitting = false;
  final List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.length <= 5) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(picked.take(5));
      });
    } else if (picked.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only select up to 5 images.")),
      );
    }
  }

  Future<List<String>> _uploadImages(String itemId) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final originalFile = File(_selectedImages[i].path);
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        '${originalFile.parent.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 75,
      );

      if (compressedFile == null) continue;

      final fileName = path.basename(compressedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('items/$itemId/image_$i-$fileName');

      final uploadTask = await ref.putFile(File(compressedFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  void _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Create Firestore document reference first
      final docRef = FirebaseFirestore.instance.collection('items').doc();

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(docRef.id);
      }

      await docRef.set({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'value': int.parse(_valueController.text.trim()),
        'condition': _condition,
        'location': _location,
        'images': imageUrls,
        'tags': [], // You can add tagging later
        'ownerId': user.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item posted successfully!")),
      );

      _formKey.currentState?.reset();
      setState(() {
        _selectedImages.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post New Item")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Item Title'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Estimated Value (KES)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _condition,
                items: const [
                  DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                  DropdownMenuItem(value: 'Good', child: Text('Good')),
                  DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                  DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                ],
                onChanged: (value) => setState(() => _condition = value!),
                decoration: const InputDecoration(labelText: 'Condition'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _location,
                decoration: const InputDecoration(labelText: 'Location'),
                onChanged: (value) => _location = value.trim(),
              ),
              const SizedBox(height: 24),

              // Image preview
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(img.path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text("Pick up to 5 images"),
              ),
              const SizedBox(height: 20),

              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Post Item"),
                onPressed: _submitItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
