import 'package:flutter_naver_map/flutter_naver_map.dart';

Future<void> initializeNaverMap({
  required String clientId,
  void Function(Object error)? onAuthFailed,
}) async {
  await FlutterNaverMap().init(
    clientId: clientId,
    onAuthFailed: (error) {
      onAuthFailed?.call(error);
    },
  );
}
