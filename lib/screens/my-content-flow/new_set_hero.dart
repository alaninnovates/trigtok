import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trig_tok/components/page_body.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:file_picker/_internal/file_picker_web.dart';

class NewSetHero extends StatefulWidget {
  final String heroTag;
  const NewSetHero({super.key, required this.heroTag});

  @override
  State<NewSetHero> createState() => _NewSetHeroState();
}

class _NewSetHeroState extends State<NewSetHero> {
  final titleController = TextEditingController();
  final subjectController = TextEditingController();
  final contentController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<PlatformFile> selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Study Set')),
        body: PageBody(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Set Title',
                          alignLabelWithHint: true,
                          hintText: 'Enter a title for your study set',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          alignLabelWithHint: true,
                          hintText: 'Enter the subject for this set',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          alignLabelWithHint: true,
                          hintText: 'Add your study content here',
                          counterText: '${contentController.text.length}/5000',
                        ),
                        maxLines: 10,
                        maxLength: 5000,
                        validator: (value) {
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Attachments:'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add Files'),
                        onPressed: () async {
                          if (kIsWeb) {
                            FilePickerWeb.registerWith(Registrar());
                          }

                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'jpg',
                                  'jpeg',
                                  'png',
                                  'pdf',
                                ],
                                allowMultiple: true,
                              );

                          if (result != null) {
                            setState(() {
                              selectedFiles.addAll(result.files);
                            });
                          } else {
                            // User canceled the picker
                          }
                        },
                      ),
                      if (selectedFiles.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                selectedFiles.map((file) {
                                  return ListTile(
                                    title: Text(file.name),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          selectedFiles.remove(file);
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Add the creation logic here
                      }
                    },
                    child: const Text('Create', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
