import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../domain/auth_failure.dart';

String fieldErrorMessage(FieldError error) => switch (error) {
      FieldError.emailRequired => AppStrings.errEmailRequired,
      FieldError.emailInvalid => AppStrings.errEmailInvalid,
      FieldError.passwordRequired => AppStrings.errPasswordRequired,
      FieldError.passwordWeak => AppStrings.passwordRule,
      FieldError.nameRequired => AppStrings.errNameRequired,
      FieldError.nameTooLong => AppStrings.errNameTooLong,
    };

/// Trả về null nếu lỗi không cần hiển thị (ví dụ người dùng tự hủy).
String? authFailureMessage(AuthFailure failure) => switch (failure) {
      InvalidCredentials() => AppStrings.errInvalidCredentials,
      EmailAlreadyInUse() => AppStrings.errEmailInUse,
      EmailNotVerified() => AppStrings.errEmailNotVerified,
      WeakPassword() => AppStrings.passwordRule,
      NetworkFailure() => AppStrings.errNetwork,
      TooManyRequests() => AppStrings.errTooManyRequests,
      UserCancelled() => null,
      UnknownAuthFailure() => AppStrings.errUnknown,
    };
