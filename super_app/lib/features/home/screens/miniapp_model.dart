class MiniApp {
  final String type;
  final String appName;
  final String displayName;
  final String version;
  final String? iconUrl;
  final String? packageUrl;
  final String? remoteUrl;

  MiniApp({
    required this.type,
    required this.appName,
    required this.displayName,
    required this.version,
    this.iconUrl,
    this.packageUrl,
    this.remoteUrl,
  });

  factory MiniApp.fromJson(Map<String, dynamic> json) {
    return MiniApp(
      type: json['type'] as String,
      appName: json['appName'] as String,
      displayName: json['displayName'] as String,
      version: json['version'] as String,
      iconUrl: json['iconUrl'] as String?,
      packageUrl: json['packageUrl'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
    );
  }
}