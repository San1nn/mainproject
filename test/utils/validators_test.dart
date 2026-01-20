import 'package:flutter_test/flutter_test.dart';
import 'package:mainproject/utils/validators.dart';
import 'package:mainproject/constants.dart';

void main() {
  group('Validators', () {
    group('Email Validation', () {
      test('Valid email passes validation', () {
        expect(Validators.validateEmail('user@example.com'), null);
        expect(Validators.validateEmail('test.email+tag@domain.co.uk'), null);
        expect(Validators.validateEmail('first_last@test.org'), null);
      });

      test('Empty email fails validation', () {
        expect(
          Validators.validateEmail(''),
          AppStrings.emailRequired,
        );
        expect(
          Validators.validateEmail(null),
          AppStrings.emailRequired,
        );
      });

      test('Invalid email format fails validation', () {
        expect(
          Validators.validateEmail('notanemail'),
          AppStrings.emailInvalid,
        );
        expect(
          Validators.validateEmail('user@'),
          AppStrings.emailInvalid,
        );
        expect(
          Validators.validateEmail('user@.com'),
          AppStrings.emailInvalid,
        );
        expect(
          Validators.validateEmail('user @example.com'),
          AppStrings.emailInvalid,
        );
      });

      test('Email with special characters', () {
        expect(Validators.validateEmail('user+tag@domain.com'), null);
        expect(Validators.validateEmail('user_name@domain.com'), null);
        expect(Validators.validateEmail('user-name@domain.com'), null);
      });
    });

    group('Password Validation', () {
      test('Valid password passes validation', () {
        expect(Validators.validatePassword('password123'), null);
        expect(Validators.validatePassword('SecurePass2024'), null);
        expect(Validators.validatePassword('longpasswordwithmanycharacters'), null);
      });

      test('Empty password fails validation', () {
        expect(
          Validators.validatePassword(''),
          AppStrings.passwordRequired,
        );
        expect(
          Validators.validatePassword(null),
          AppStrings.passwordRequired,
        );
      });

      test('Password too short fails validation', () {
        expect(
          Validators.validatePassword('12345'),
          AppStrings.passwordTooShort,
        );
        expect(
          Validators.validatePassword('abc'),
          AppStrings.passwordTooShort,
        );
      });

      test('Minimum valid password length is 6', () {
        expect(Validators.validatePassword('123456'), null);
        expect(Validators.validatePassword('12345'), AppStrings.passwordTooShort);
      });
    });

    group('Confirm Password Validation', () {
      test('Matching passwords pass validation', () {
        expect(
          Validators.validateConfirmPassword('password123', 'password123'),
          null,
        );
      });

      test('Empty confirm password fails validation', () {
        expect(
          Validators.validateConfirmPassword('', 'password123'),
          AppStrings.passwordRequired,
        );
        expect(
          Validators.validateConfirmPassword(null, 'password123'),
          AppStrings.passwordRequired,
        );
      });

      test('Non-matching passwords fail validation', () {
        expect(
          Validators.validateConfirmPassword('password456', 'password123'),
          AppStrings.passwordMismatch,
        );
        expect(
          Validators.validateConfirmPassword('different', 'password'),
          AppStrings.passwordMismatch,
        );
      });

      test('Case-sensitive password comparison', () {
        expect(
          Validators.validateConfirmPassword('Password123', 'password123'),
          AppStrings.passwordMismatch,
        );
      });
    });

    group('Name Validation', () {
      test('Valid names pass validation', () {
        expect(Validators.validateName('John'), null);
        expect(Validators.validateName('Mary Jane'), null);
        expect(Validators.validateName('José García'), null);
      });

      test('Empty name fails validation', () {
        expect(
          Validators.validateName(''),
          AppStrings.nameRequired,
        );
        expect(
          Validators.validateName(null),
          AppStrings.nameRequired,
        );
      });

      test('Single character name fails validation', () {
        expect(
          Validators.validateName('A'),
          isNotNull,
        );
      });

      test('Name with exactly 2 characters passes validation', () {
        expect(Validators.validateName('Jo'), null);
        expect(Validators.validateName('AB'), null);
      });

      test('Long names pass validation', () {
        expect(
          Validators.validateName('Alexander Maximilian Von Humboldt'),
          null,
        );
      });
    });

    group('Combined Validation', () {
      test('All valid registration data', () {
        expect(Validators.validateEmail('user@example.com'), null);
        expect(Validators.validatePassword('password123'), null);
        expect(Validators.validateConfirmPassword('password123', 'password123'), null);
        expect(Validators.validateName('John Doe'), null);
      });

      test('Invalid registration data', () {
        expect(Validators.validateEmail('invalid-email'), isNotNull);
        expect(Validators.validatePassword('123'), isNotNull);
        expect(Validators.validateConfirmPassword('pass456', 'password'), isNotNull);
        expect(Validators.validateName('J'), isNotNull);
      });
    });
  });
}
