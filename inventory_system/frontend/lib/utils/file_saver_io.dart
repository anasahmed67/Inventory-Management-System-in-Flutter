import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(String content, String fileName, String mimeType) async {
  // Use the application documents directory as it doesn't require extra permissions on Android
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsString(content);
  
  // We print the path so the user can see it in logs/console
  print('Export successful: File saved to $filePath');
}
