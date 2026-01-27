import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Controllers {
  Future<bool> checkStoragePermission(BuildContext context) async {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;

    final result = await Permission.manageExternalStorage.request();
    if (result.isGranted) return true;

    _showPermissionDialog(context, 'Storage');
    return false;
  }

  Future<bool> checkCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    _showPermissionDialog(context, 'Camera');
    return false;
  }

  void _showPermissionDialog(BuildContext context, String permission) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          '$permission permission is required to continue. Please enable it from settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
