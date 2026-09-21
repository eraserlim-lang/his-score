import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 설치된 앱의 버전. pubspec.yaml 의 version 에서 온다.
///
/// 기기에 올라간 빌드가 어느 것인지 알아야 버그를 재현하고 고친 판이
/// 들어갔는지 확인할 수 있다. 설정의 정보 칸에 보인다.
final appVersionProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
