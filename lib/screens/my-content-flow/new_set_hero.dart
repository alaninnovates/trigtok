import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trig_tok/components/page_body.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:trig_tok/screens/my-content-flow/attachment_uploader.dart';

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
                        onChanged: (value) {
                          formKey.currentState!.validate();
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
                        onChanged: (value) {
                          formKey.currentState!.validate();
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
                      AttachmentUploader(
                        selectedFiles: selectedFiles,
                        onFilesUpdated: (files) {
                          setState(() {
                            selectedFiles = files;
                          });
                        },
                        maxFileSize: 10 * 1024 * 1024,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        if (contentController.text.isEmpty &&
                            selectedFiles.isEmpty) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Missing Content'),
                                  content: const Text(
                                    'You must add content or files to create a set.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                          );
                          return;
                        }
                        var apiUrl = dotenv.env['API_URL'];
                        var request = http.MultipartRequest(
                          'POST',
                          Uri.parse('$apiUrl/new-set'),
                        );
                        request.headers['authorization'] =
                            Supabase
                                .instance
                                .client
                                .auth
                                .currentSession
                                ?.accessToken ??
                            '';
                        request.fields['title'] = titleController.text;
                        request.fields['subject'] = subjectController.text;
                        request.fields['content'] = contentController.text;
                        for (var file in selectedFiles) {
                          request.files.add(
                            http.MultipartFile.fromBytes(
                              'files',
                              file.bytes!,
                              filename: file.name,
                            ),
                          );
                        }
                        request
                            .send()
                            .then((response) {
                              if (response.statusCode == 200) {
                                Navigator.of(context).pop();
                              } else {
                                print(
                                  'Failed to create study set: ${response.statusCode} ${response.reasonPhrase}',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to create study set. Try again later.',
                                    ),
                                  ),
                                );
                              }
                            })
                            .catchError((error) {
                              print(
                                'Failed to create study set: ${error.toString()}',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to create study set. Try again later.',
                                  ),
                                ),
                              );
                            });
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
