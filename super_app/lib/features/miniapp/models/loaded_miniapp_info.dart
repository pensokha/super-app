import 'package:super_app/features/miniapp/models/miniapp_manifest.dart';

class LoadedMiniAppInfo {
  final String localUrl;
  final MiniAppManifest manifest;

  LoadedMiniAppInfo({required this.localUrl, required this.manifest});
}