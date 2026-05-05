import 'package:flutter/material.dart';
import 'package:super_app/features/miniapp/screens/miniapp_container_screen.dart';
import 'package:super_app/features/miniapp/services/miniapp_loader_service.dart';
import 'package:super_app/features/miniapp/models/miniapp_model.dart';
import 'package:super_app/features/miniapp/models/miniapp_manifest.dart'; // Added missing import
import 'package:super_app/features/miniapp/models/loaded_miniapp_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use a Future to manage the state of fetching the mini-app list.
  late Future<List<MiniApp>> _miniAppsFuture;
  // Use a Set to track which specific mini-app is currently being launched.
  final Set<String> _launchingApps = {};
  final _miniAppLoader = MiniAppLoaderService();

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  void _fetchApps() {
    setState(() {
      _miniAppsFuture = _miniAppLoader.fetchMiniAppList();
    });
  }

  void _launchDynamicMiniApp(String appName) async {
    setState(() {
      _launchingApps.add(appName);
    });

    try {
      final LoadedMiniAppInfo appInfo = await _miniAppLoader.loadMiniApp(appName: appName);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MiniAppContainerScreen(url: appInfo.localUrl, manifest: appInfo.manifest),
          ),
        );
      }
    } catch (e) {
      // Handle errors, e.g., show a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Mini App: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _launchingApps.remove(appName);
        });
      }
    }
  }

  void _launchRemoteMiniApp(String url, String appName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MiniAppContainerScreen(
          url: url,
          manifest: MiniAppManifest(name: appName, version: 'remote', permissions: []), // Remote apps have no manifest initially
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini App Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchApps,
            tooltip: 'Refresh Mini Apps',
          ),
        ],
      ),
      body: FutureBuilder<List<MiniApp>>(
        future: _miniAppsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Failed to load Mini Apps: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchApps,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final miniApps = snapshot.data ?? [];

          return ListView.builder(
            itemCount: miniApps.length,
            itemBuilder: (context, index) {
              final app = miniApps[index];
              final isLaunching = _launchingApps.contains(app.appName);
              return ListTile(
                leading: isLaunching ? const CircularProgressIndicator() : CircleAvatar(backgroundImage: app.iconUrl != null && app.iconUrl!.isNotEmpty ? NetworkImage(app.iconUrl!) : null, child: (app.iconUrl == null || app.iconUrl!.isEmpty) ? Text(app.displayName.isNotEmpty ? app.displayName[0] : '?') : null),
                title: Text(app.displayName),
                subtitle: Text('Type: ${app.type} - Version: ${app.version}'),
                onTap: isLaunching
                    ? null
                    : () {
                        if (app.type == 'local') {
                          _launchDynamicMiniApp(app.appName);
                        } else if (app.type == 'remote' && app.remoteUrl != null) {
                          // For remote apps, we create a dummy manifest for now.
                          // In a real scenario, you might fetch a manifest from the remote URL
                          // or have a predefined set of permissions for remote apps.
                          _launchRemoteMiniApp(app.remoteUrl!, app.appName);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot launch app: Invalid configuration for ${app.displayName}'),
                            ),
                          );
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}
