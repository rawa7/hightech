class Banner {
  final String id;
  final String title;
  final String image;
  final String? link;
  final String status;
  final String createdAt;
  final String? webPath;
  final String? filename;

  Banner({
    required this.id,
    required this.title,
    required this.image,
    this.link,
    required this.status,
    required this.createdAt,
    this.webPath,
    this.filename,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      image: json['image'].toString(),
      link: json['link'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? '',
      webPath: json['web_path'],
      filename: json['filename'],
    );
  }

  String get imageUrl {
    if (webPath != null) {
      // Convert the relative path to absolute URL
      return 'https://dasroor.com/hightech/${webPath!.replaceAll('..\\/', '').replaceAll('../', '')}';
    }
    return '';
  }
}
