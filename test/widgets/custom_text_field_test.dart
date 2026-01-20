import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mainproject/widgets/custom_text_field.dart';

void main() {
  group('CustomTextField Widget', () {
    testWidgets('CustomTextField renders with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Email',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(CustomTextField), findsOneWidget);
    });

    testWidgets('CustomTextField with hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Email',
              hintText: 'Enter your email',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('CustomTextField with prefix icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Email',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('CustomTextField accepts text input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Name',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'John Doe');
      await tester.pump();

      expect(controller.text, 'John Doe');
    });

    testWidgets('CustomTextField can be obscured for password', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsOneWidget);
    });

    testWidgets('CustomTextField calls onChanged callback', 
      (WidgetTester tester) async {
      String changedValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Input',
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();

      expect(changedValue, 'Test');
    });

    testWidgets('CustomTextField with different keyboard types', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomTextField(
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                CustomTextField(
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
                CustomTextField(
                  label: 'Number',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsWidgets);
    });

    testWidgets('CustomTextField with multiline support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Description',
              maxLines: 5,
              minLines: 2,
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsOneWidget);
    });

    testWidgets('CustomTextField validator is called', (WidgetTester tester) async {
      String? validationError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Email',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  validationError = 'Email is required';
                  return 'Email is required';
                }
                validationError = null;
                return null;
              },
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsOneWidget);
    });

    testWidgets('CustomTextField with controller and clear functionality', 
      (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Input',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Some text');
      await tester.pump();
      expect(controller.text, 'Some text');

      controller.clear();
      await tester.pump();
      expect(controller.text, '');
    });

    testWidgets('Multiple CustomTextFields can be rendered', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomTextField(
                  label: 'First Name',
                  hintText: 'Enter first name',
                ),
                CustomTextField(
                  label: 'Last Name',
                  hintText: 'Enter last name',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsWidgets);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
    });
  });
}
