import 'package:cleanify/features/permissions/domain/media_access.dart';

class FakeMediaAccessGateway implements MediaAccessGateway {
  FakeMediaAccessGateway({
    this.currentValue = MediaAccess.unknown,
    this.requestResult = MediaAccess.granted,
    this.requestDelay = Duration.zero,
    this.throwOnRequest = false,
  });

  MediaAccess currentValue;
  MediaAccess requestResult;
  Duration requestDelay;
  bool throwOnRequest;

  int requestCalls = 0;
  int openSettingsCalls = 0;
  int manageLimitedCalls = 0;

  @override
  Future<MediaAccess> current() async => currentValue;

  @override
  Future<MediaAccess> request() async {
    requestCalls++;
    if (requestDelay > Duration.zero) await Future<void>.delayed(requestDelay);
    if (throwOnRequest) throw StateError('plugin error');
    currentValue = requestResult;
    return requestResult;
  }

  @override
  Future<void> openSettings() async => openSettingsCalls++;

  @override
  Future<void> manageLimited() async => manageLimitedCalls++;
}
