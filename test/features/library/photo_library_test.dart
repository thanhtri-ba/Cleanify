import 'package:cleanify/features/library/application/library_controller.dart';
import 'package:cleanify/features/library/presentation/photo_library_page.dart';
import 'package:cleanify/features/permissions/application/media_access_controller.dart';
import 'package:cleanify/features/permissions/domain/media_access.dart';
import 'package:cleanify/features/scan/application/scan_providers.dart';
import 'package:cleanify/features/scan/domain/media_item.dart';
import 'package:cleanify/features/scan/presentation/widgets/media_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

class _FakeGateway implements MediaAccessGateway {
  _FakeGateway(this.access);

  final MediaAccess access;

  @override
  Future<MediaAccess> current() async => access;

  @override
  Future<MediaAccess> request() async => access;

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> manageLimited() async {}
}

Future<ProviderContainer> pumpLibrary(
  WidgetTester tester, {
  required List<MediaItem> items,
  MediaAccess access = MediaAccess.granted,
}) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    mediaSourceProvider.overrideWithValue(FakeMediaSource(items)),
    mediaAccessGatewayProvider.overrideWithValue(_FakeGateway(access)),
    // Plugin ảnh không chạy trong test: coi như không tải được ảnh thu nhỏ.
    thumbnailProvider.overrideWith((ref, request) async => null),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: PhotoLibraryPage()),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('hiện lưới mọi ảnh/video và tổng số mục', (tester) async {
    await pumpLibrary(tester, items: [
      photo('a'),
      photo('b'),
      video('c'),
      photo('d'),
      photo('e'),
    ]);

    expect(find.text('5 items'), findsOneWidget);
    expect(find.byType(MediaThumbnail), findsNWidgets(5));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('chưa có quyền ảnh: báo rõ và không nạp thư viện',
      (tester) async {
    final container = await pumpLibrary(
      tester,
      items: [photo('a')],
      access: MediaAccess.denied,
    );

    expect(find.text('Photo access is off'), findsOneWidget);
    expect(find.byType(MediaThumbnail), findsNothing);
    expect(container.read(libraryControllerProvider).items, isEmpty);
  });

  testWidgets('thư viện trống', (tester) async {
    await pumpLibrary(tester, items: const []);

    expect(find.text('No photos or videos yet'), findsOneWidget);
  });

  testWidgets('cuộn xuống thì nạp thêm trang kế tiếp', (tester) async {
    final items = [for (var i = 0; i < 300; i++) photo('p$i')];
    final container = await pumpLibrary(tester, items: items);
    expect(container.read(libraryControllerProvider).items, hasLength(120));

    await tester.drag(find.byType(GridView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(container.read(libraryControllerProvider).items.length,
        greaterThan(120));

    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(GridView), const Offset(0, -20000));
      await tester.pumpAndSettle();
    }
    final state = container.read(libraryControllerProvider);
    expect(state.items, hasLength(300));
    expect(state.hasMore, isFalse);
  });

  testWidgets('bấm một ảnh mở màn xem lớn và vuốt sang ảnh kế', (tester) async {
    await pumpLibrary(tester, items: [photo('a'), photo('b'), photo('c')]);

    await tester.tap(find.byType(MediaThumbnail).at(1));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsNothing);
  });
}
