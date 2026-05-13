import 'package:flutter/material.dart';

import 'operations_app.dart';
import 'operations_data.dart';

void main() {
  const screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
  final repository = screenshotMode
      ? MemoryOperationsRepository(seedOperations())
      : FileOperationsRepository();

  runApp(
    SCPBreuxOpsApp(repository: repository, screenshotMode: screenshotMode),
  );
}
