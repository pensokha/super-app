class MiniAppManifest {
  final String name;
  final String version;
  final List<String> permissions;
  final String? csp; // New field for Content Security Policy

  MiniAppManifest({
    required this.name,
    required this.version,
    required this.permissions,
    this.csp,
  });

  factory MiniAppManifest.fromJson(Map<String, dynamic> json) {
    return MiniAppManifest(
      name: json['name'] as String,
      version: json['version'] as String,
      permissions: List<String>.from(json['permissions'] ?? []),
      csp: json['csp'] as String?,
    );
  }
}