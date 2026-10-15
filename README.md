# BudgetBuddy

Student budget and expense tracker built with Flutter and Firebase.

## Development target
Chrome first; Android device testing before submission.

## Setup
1. Install the team's agreed Flutter SDK version.
2. Clone this repository.
3. Run flutter pub get.
4. Run flutter run -d chrome.

## Quality checks
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

## Firebase
- Use the shared team Firebase project.
- Client configuration is committed.
- Never commit Admin SDK keys or signing secrets.
- Only designated maintainers deploy rules.

## Team workflow
- Create a feature branch.
- Open a pull request.
- Have another member review it.
- Keep main runnable.

## Shared conventions
Read docs/team_contract.md before implementing models or features.

## Current implementation
- Firebase initialization.
- Placeholder Expenses, Summary, and Budget tabs.
- Shared expense categories.
- Starter widget test.
- Initial ownership-based Firestore rules.

Authentication screens and application features are not implemented yet.