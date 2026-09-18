import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 앱이 쓰는 폴더 위치.
///
/// DB 에는 항상 [docsRoot] 기준 상대 경로만 저장한다.
/// iOS 는 앱 업데이트 때 컨테이너 절대 경로가 바뀌므로 절대 경로를 넣으면 깨진다.
class AppPaths {
  AppPaths(this.docsRoot);

  final Directory docsRoot;

  Directory get scoresDir => Directory(p.join(docsRoot.path, 'scores'));
  Directory get coversDir => Directory(p.join(docsRoot.path, 'covers'));
  Directory get recordingsDir => Directory(p.join(docsRoot.path, 'recordings'));

  Future<void> ensureCreated() async {
    for (final dir in [scoresDir, coversDir, recordingsDir]) {
      if (!dir.existsSync()) await dir.create(recursive: true);
    }
  }

  /// DB 에 저장된 상대 경로를 실제 파일로 되돌린다.
  File resolve(String relativePath) =>
      File(p.join(docsRoot.path, relativePath));

  String relativeOf(File file) => p.relative(file.path, from: docsRoot.path);
}

final appPathsProvider = FutureProvider<AppPaths>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final paths = AppPaths(dir);
  await paths.ensureCreated();
  return paths;
});
