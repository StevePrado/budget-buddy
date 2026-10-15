# BudgetBuddy Team Contract

## Platforms
- Chrome for initial development.
- Android for final device-feature testing.
- Shared code must remain compatible with both.

## Authentication
- Firebase Email/Password.
- Each app user accesses only their own data.

## Firestore paths
- users/{uid}/budgets/current
- users/{uid}/expenses/{expenseId}

## Expense fields
- name: String
- amountMinor: int
- category: String from expenseCategories
- date: Firestore Timestamp
- notes: String; empty when unused
- receiptUrl: String or null
- receiptStoragePath: String or null
- createdAt: Firestore Timestamp
- updatedAt: Firestore Timestamp

## Budget fields
- dailyMinor: int
- weeklyMinor: int
- monthlyMinor: int
- updatedAt: Firestore Timestamp

## Money
- Proposed currency: PHP; confirm as a group.
- Store integer minor units.
- PHP 125.50 is stored as 12550.
- Convert and format values for display.

## Budget periods
- Daily: local calendar day.
- Weekly: Monday through Sunday.
- Monthly: local calendar month.
- Range queries use an inclusive start and exclusive end.
- Summaries use expense date, not createdAt.
- Daily, weekly, and monthly budgets are separate limits.
- Never add these three limits together.

## Code ownership
- Services contain Firebase operations.
- Providers expose shared state and loading/error information.
- Screens display state and collect input.
- Cancel user-specific listeners and clear state on logout.

## Receipts
- Optional per expense.
- App must provide the required camera/gallery feature.
- Proposed Storage path:
  users/{uid}/receipts/{uniqueFileName}

## Web compatibility
- Do not use dart:io File directly in shared UI/upload code.
- Use web-compatible image selection and byte-based uploads.
- Android local notifications will be implemented and tested
  when the Android environment is ready.