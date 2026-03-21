
class FileNode {
  final String name;
  final String path;
  final FileType type; // Sustituye al booleano
  final int sizeInBytes;
  final String permissions;
  final DateTime lastModified;

  FileNode({
    required this.name,
    required this.path,
    required this.type,
    required this.sizeInBytes,
    required this.permissions,
    required this.lastModified,
  });

  // El Dev A usará esto para decidir qué icono mostrar
  bool get isDirectory => type == FileType.directory;

  // Lógica para que el Dev C asigne el tipo según la extensión
  static FileType parseType(String fileName, bool isDir) {
    if (isDir) return FileType.directory;

    final name = fileName.toLowerCase();
    if (name.endsWith('.txt')) return FileType.txt;
    if (name.endsWith('.md')) return FileType.markdown;
    if (name.endsWith('.png') || name.endsWith('.jpg')) return FileType.image;
    if (name.endsWith('.conf') || name.endsWith('.yaml')) return FileType.config;

    return FileType.unknown;
  }
}

enum FileType {
  directory,
  txt,
  markdown,
  image,
  pdf,
  config, // .conf, .yaml, .json
  unknown
}