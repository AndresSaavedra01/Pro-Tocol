
import 'package:dartssh2/dartssh2.dart';
import 'package:pro_tocol/entity/FileNode.dart';

class SFTPService {
  final SSHClient _client;
  SftpClient? _sftpInternal;

  SFTPService(this._client);

  Future<SftpClient> _ensureSftp() async {
    _sftpInternal ??= await _client.sftp();
    return _sftpInternal!;
  }

  /// Lista el contenido de un directorio y lo mapea a objetos FileNode
  Future<List<FileNode>> listDirectory(String directoryPath) async {
    final sftp = await _ensureSftp();

    // Obtenemos la lista nativa de dartssh2
    final List<SftpName> items = await sftp.listdir(directoryPath);

    // Convertimos cada SftpName a nuestro FileNode
    return items.map((item) {
      // Normalizamos el path (evita dobles slashes //)
      final String fullPath = directoryPath.endsWith('/')
          ? '$directoryPath${item.filename}'
          : '$directoryPath/${item.filename}';

      return FileNode(
        name: item.filename,
        path: fullPath,
        type: FileNode.parseType(item.filename, item.attr.isDirectory),
        sizeInBytes: item.attr.size ?? 0,
        // Convertimos los permisos (mode) a String legible o guardamos el int
        permissions: item.attr.mode?.toString() ?? '---',
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          (item.attr.modifyTime ?? 0) * 1000,
        ),
      );
    }).toList();
  }
}