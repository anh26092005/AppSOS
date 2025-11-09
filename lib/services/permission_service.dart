import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Kiểm tra và xin quyền truy cập vị trí
  static Future<bool> requestLocationPermission() async {
    // Kiểm tra quyền hiện tại
    var status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Xin quyền
      var result = await Permission.location.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Mở settings nếu bị từ chối vĩnh viễn
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Xin quyền vị trí chính xác (fine location)
  static Future<bool> requestFineLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return true;
    }

    var result = await Permission.locationWhenInUse.request();

    if (result.isDenied || result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return result.isGranted;
  }

  // Xin quyền truy cập ảnh/thư viện
  static Future<bool> requestPhotosPermission() async {
    var status = await Permission.photos.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      var result = await Permission.photos.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Xin quyền truy cập storage (Android)
  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      var result = await Permission.storage.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Xin quyền camera
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      var result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Xin quyền truy cập danh bạ
  static Future<bool> requestContactsPermission() async {
    var status = await Permission.contacts.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      var result = await Permission.contacts.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Xin tất cả quyền cơ bản cùng lúc
  static Future<Map<Permission, PermissionStatus>> requestAllBasicPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.photos,
      Permission.contacts,
    ].request();

    return statuses;
  }

  // Kiểm tra trạng thái quyền
  static Future<bool> isPermissionGranted(Permission permission) async {
    var status = await permission.status;
    return status.isGranted;
  }

  // Mở settings app
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

