import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/features/miniapp/models/miniapp_model.dart';

// In a real app, this would be in a config file.
// Use 10.0.2.2 for the Android emulator to connect to your host machine's localhost.
final String _backendUrl = kIsWeb || !Platform.isAndroid ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

class MiniAppLoaderService {
  /// Ensures the mini-app is up-to-date and ready to be used.
  ///
  /// Returns the local path to the mini-app's index.html file.
  Future<String> loadMiniApp({required String appName}) async {
    final appDir = await _getAppDirectory(appName);
    final indexFile = File(p.join(appDir.path, 'index.html'));

    try {
      // 1. Fetch the latest metadata from the backend
      final metadata = await _fetchMiniAppMetadata(appName);
      if (metadata == null) {
        // If we can't reach the backend, try to load from cache
        if (await indexFile.exists()) {
          debugPrint('Backend unreachable. Loading "$appName" from cache.');
          return indexFile.uri.toString();
        }
        throw Exception('MiniApp not found and backend is unreachable.');
      }

      // 2. Check the currently installed version
      final installedVersion = await _getInstalledVersion(appName);

      // 3. Compare versions and update if necessary
      if (metadata['version'] != installedVersion) {
        debugPrint('New version ${metadata['version']} found for "$appName". Updating...');
        await _downloadAndUnpackMiniApp(metadata, appDir);
        await _setInstalledVersion(appName, metadata['version']);
      } else {
        debugPrint('MiniApp "$appName" is up to date (version $installedVersion).');
      }
    } catch (e) {
      debugPrint('An error occurred during update check: $e. Trying to load from cache.');
      // If any error occurs (network, etc.), fall back to loading from cache if it exists.
      if (await indexFile.exists()) {
        return indexFile.uri.toString();
      }
      // If there's no cached version, re-throw the error.
      rethrow;
    }

    // 4. Return the path to the local index.html
    if (!await indexFile.exists()) {
      throw Exception('Failed to load MiniApp: index.html not found after process.');
    }
    return indexFile.uri.toString();
  }

  Future<List<MiniApp>> fetchMiniAppList() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/miniapps'));
      if (response.statusCode == 200) {
        final List<dynamic> appListJson = jsonDecode(response.body);
        return appListJson.map((json) => MiniApp.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load mini-app list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to fetch mini-app list: $e');
      // Re-throwing the exception to be handled by the UI.
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchMiniAppMetadata(String appName) async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/miniapps?appName=$appName'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Failed to fetch metadata: $e');
    }
    return null;
  }

  Future<void> _downloadAndUnpackMiniApp(Map<String, dynamic> metadata, Directory targetDir) async {
    final packageUrl = metadata['packageUrl'];
    if (packageUrl == null) {
      throw Exception('Package URL not found in metadata.');
    }

    // Clean the directory before unpacking a new version
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    final response = await http.get(Uri.parse(packageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download package: ${response.statusCode}');
    }

    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    extractArchiveToDisk(archive, targetDir.path);
    debugPrint('Successfully downloaded and unpacked ${metadata['appName']} version ${metadata['version']}.');
  }

  Future<String?> _getInstalledVersion(String appName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('miniapp_version_$appName');
  }

  Future<void> _setInstalledVersion(String appName, String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('miniapp_version_$appName', version);
  }

  Future<Directory> _getAppDirectory(String appName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(docsDir.path, 'miniapps', appName));
  }
}