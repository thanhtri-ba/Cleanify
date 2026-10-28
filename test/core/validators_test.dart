import 'package:cleanify/core/utils/email_masking.dart';
import 'package:cleanify/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('báo thiếu khi rỗng hoặc chỉ có khoảng trắng', () {
      expect(Validators.email(''), FieldError.emailRequired);
      expect(Validators.email('   '), FieldError.emailRequired);
    });

    test('chấp nhận email hợp lệ', () {
      for (final value in ['you@example.com', ' a.b+tag@sub.example.co ']) {
        expect(Validators.email(value), isNull, reason: value);
      }
    });

    test('từ chối email sai định dạng', () {
      for (final value in [
        'plain',
        'a@b',
        '@example.com',
        'a@@example.com',
        'a b@example.com',
        'a@example..com',
        'a@example.com.',
      ]) {
        expect(Validators.email(value), FieldError.emailInvalid, reason: value);
      }
    });

    test('từ chối email quá dài', () {
      final long = '${'a' * 250}@example.com';
      expect(Validators.email(long), FieldError.emailInvalid);
    });
  });

  group('Validators.newPassword', () {
    test('chấp nhận mật khẩu đủ quy tắc', () {
      expect(Validators.newPassword('Abcdef12'), isNull);
    });

    test('từ chối khi thiếu một trong các quy tắc', () {
      for (final value in ['Ab1', 'abcdefg1', 'ABCDEFG1', 'Abcdefgh']) {
        expect(Validators.newPassword(value), FieldError.passwordWeak,
            reason: value);
      }
    });

    test('rỗng báo thiếu, quá dài báo yếu', () {
      expect(Validators.newPassword(''), FieldError.passwordRequired);
      expect(
        Validators.newPassword('Aa1${'x' * 200}'),
        FieldError.passwordWeak,
      );
    });

    test('không cắt khoảng trắng của mật khẩu', () {
      expect(Validators.newPassword('Abcdef1 '), isNull);
    });
  });

  group('Validators.requiredPassword', () {
    test('chỉ yêu cầu có nhập', () {
      expect(Validators.requiredPassword(''), FieldError.passwordRequired);
      expect(Validators.requiredPassword('x'), isNull);
    });
  });

  group('Validators.name', () {
    test('rỗng báo thiếu, quá dài báo lỗi, bình thường hợp lệ', () {
      expect(Validators.name('  '), FieldError.nameRequired);
      expect(Validators.name('a' * 81), FieldError.nameTooLong);
      expect(Validators.name('An  Nguyen'), isNull);
    });

    test('chuẩn hóa khoảng trắng', () {
      expect(Validators.normalizeName('  An   Nguyen '), 'An Nguyen');
    });
  });

  test('normalizeEmail cắt khoảng trắng và đưa về chữ thường', () {
    expect(Validators.normalizeEmail(' You@Example.COM '), 'you@example.com');
  });

  group('maskEmail', () {
    test('che phần tên, giữ ký tự đầu và tên miền', () {
      expect(maskEmail('example@gmail.com'), 'e••••@gmail.com');
      expect(maskEmail('a@x.com'), 'a••••@x.com');
    });

    test('đầu vào không hợp lệ không làm lộ nội dung', () {
      expect(maskEmail('invalid'), '••••');
      expect(maskEmail(''), '••••');
      expect(maskEmail('@x.com'), '••••');
    });
  });
}
