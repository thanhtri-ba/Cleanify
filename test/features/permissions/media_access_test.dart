import 'package:cleanify/features/permissions/application/media_access_controller.dart';
import 'package:cleanify/features/permissions/domain/media_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_access_gateway.dart';

ProviderContainer make(FakeMediaAccessGateway gateway) {
  final container = ProviderContainer(
    overrides: [mediaAccessGatewayProvider.overrideWithValue(gateway)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('resolvePhotoAccessView', () {
    PhotoAccessView view(
      MediaAccess a, {
      bool requested = false,
      bool ios = true,
    }) =>
        resolvePhotoAccessView(a, hasRequested: requested, isIos: ios);

    test('granted / limited / unknown', () {
      expect(view(MediaAccess.granted), PhotoAccessView.granted);
      expect(view(MediaAccess.limited), PhotoAccessView.limited);
      expect(view(MediaAccess.unknown), PhotoAccessView.intro);
    });

    test('iOS: denied là bị từ chối thật dù chưa xin trong phiên này', () {
      expect(view(MediaAccess.denied), PhotoAccessView.denied);
    });

    test('Android: denied trước khi xin lần nào vẫn hiện intro', () {
      expect(view(MediaAccess.denied, ios: false), PhotoAccessView.intro);
    });

    test('Android: denied sau khi đã xin thì hiện màn bị từ chối', () {
      expect(
        view(MediaAccess.denied, ios: false, requested: true),
        PhotoAccessView.denied,
      );
    });
  });

  group('MediaAccessController', () {
    test('request cập nhật trạng thái và đánh dấu đã xin', () async {
      final gateway = FakeMediaAccessGateway(requestResult: MediaAccess.limited);
      final container = make(gateway);

      final result =
          await container.read(mediaAccessProvider.notifier).request();

      final state = container.read(mediaAccessProvider);
      expect(result, MediaAccess.limited);
      expect(state.access, MediaAccess.limited);
      expect(state.hasRequested, isTrue);
      expect(state.isRequesting, isFalse);
    });

    test('bấm xin quyền hai lần liên tiếp chỉ gọi hệ điều hành một lần',
        () async {
      final gateway = FakeMediaAccessGateway(
        requestDelay: const Duration(milliseconds: 20),
      );
      final container = make(gateway);
      final notifier = container.read(mediaAccessProvider.notifier);

      final first = notifier.request();
      expect(container.read(mediaAccessProvider).isRequesting, isTrue);
      await notifier.request();
      await first;

      expect(gateway.requestCalls, 1);
    });

    test('plugin ném lỗi thì coi là denied và mở lại được nút', () async {
      final gateway = FakeMediaAccessGateway(throwOnRequest: true);
      final container = make(gateway);

      await container.read(mediaAccessProvider.notifier).request();

      final state = container.read(mediaAccessProvider);
      expect(state.access, MediaAccess.denied);
      expect(state.isRequesting, isFalse);
      expect(state.hasRequested, isTrue);
    });

    test('refresh đọc trạng thái mà không xin quyền', () async {
      final gateway = FakeMediaAccessGateway(currentValue: MediaAccess.limited);
      final container = make(gateway);

      await container.read(mediaAccessProvider.notifier).refresh();

      expect(container.read(mediaAccessProvider).access, MediaAccess.limited);
      expect(gateway.requestCalls, 0);
    });

    test('manageLimited gọi gateway rồi đọc lại trạng thái', () async {
      final gateway = FakeMediaAccessGateway(currentValue: MediaAccess.limited);
      final container = make(gateway);
      final notifier = container.read(mediaAccessProvider.notifier);

      gateway.currentValue = MediaAccess.granted;
      await notifier.manageLimited();

      expect(gateway.manageLimitedCalls, 1);
      expect(container.read(mediaAccessProvider).access, MediaAccess.granted);
    });

    test('openSettings gọi gateway', () async {
      final gateway = FakeMediaAccessGateway();
      final container = make(gateway);

      await container.read(mediaAccessProvider.notifier).openSettings();

      expect(gateway.openSettingsCalls, 1);
    });
  });
}
