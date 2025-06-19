// Create a new file called attachment_uploader.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:file_picker/_internal/file_picker_web.dart';

class AttachmentUploader extends StatefulWidget {
  final List<PlatformFile> selectedFiles;
  final Function(List<PlatformFile>) onFilesUpdated;
  final int maxFileSize;

  const AttachmentUploader({
    super.key,
    required this.selectedFiles,
    required this.onFilesUpdated,
    this.maxFileSize = 10 * 1024 * 1024,
  });

  @override
  State<AttachmentUploader> createState() => _AttachmentUploaderState();
}

class _AttachmentUploaderState extends State<AttachmentUploader> {
  int totalFileSize = 0;

  @override
  void initState() {
    super.initState();
  }

  String _getFormattedFileSize() {
    if (totalFileSize < 1024) {
      return '$totalFileSize B';
    } else if (totalFileSize < 1024 * 1024) {
      return '${(totalFileSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(totalFileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Attachments:'),
            Flexible(
              child: Text(
                '${_getFormattedFileSize()} / ${(widget.maxFileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                style: TextStyle(
                  color: totalFileSize > widget.maxFileSize ? Colors.red : null,
                  fontWeight:
                      totalFileSize > widget.maxFileSize
                          ? FontWeight.bold
                          : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('Add Files'),
          onPressed: () async {
            if (kIsWeb) {
              FilePickerWeb.registerWith(Registrar());
            }

            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
              allowMultiple: true,
            );

            if (result != null) {
              int newFilesSize = 0;
              for (var file in result.files) {
                newFilesSize += file.size;
              }

              if (totalFileSize + newFilesSize > widget.maxFileSize) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Total file size cannot exceed 10MB'),
                  ),
                );
              } else {
                List<PlatformFile> updatedFiles = [
                  ...widget.selectedFiles,
                  ...result.files,
                ];
                setState(() {
                  widget.onFilesUpdated(updatedFiles);
                  totalFileSize = 0;
                  for (var file in updatedFiles) {
                    totalFileSize += file.size;
                  }
                });
              }
            }
          },
        ),
        if (widget.selectedFiles.isNotEmpty)
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
                  widget.selectedFiles.map((file) {
                    return ListTile(
                      title: Text(file.name),
                      subtitle: Text(_formatFileSize(file.size)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          List<PlatformFile> updatedFiles = [
                            ...widget.selectedFiles,
                          ];
                          updatedFiles.remove(file);
                          setState(() {
                            widget.onFilesUpdated(updatedFiles);
                            totalFileSize -= file.size;
                          });
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}
