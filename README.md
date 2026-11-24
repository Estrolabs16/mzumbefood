# MU Food Delivery

Personal sales, expense, debt, and food-business tracking app for Tanzania, built with Flutter and Firebase.

- Firebase project: `estroshopstz`
- Android/iOS bundle: `com.mufood.mzumbefood`
- Auth: Firebase Email/Password only
- Data: Cloud Firestore, scoped to `users/{uid}/...`
- Logo/brand: `assets/logow.png`

## Requirements

- Flutter `3.47.0`
- Dart `3.13.0`
- Firebase CLI `15.22.4` or newer
- Android SDK and device/emulator for Android testing
- Access to Firebase project `estroshopstz`

## Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Firebase options are already generated in `lib/firebase_options.dart`. To regenerate them:

   ```bash
   flutterfire configure \
     --project=estroshopstz \
     --platforms=android,ios \
     --android-package-name=com.mufood.mzumbefood \
     --ios-bundle-id=com.mufood.mzumbefood \
     --display-name="MU Food Delivery" \
     -y
   ```

3. In Firebase Console, enable **Authentication → Sign-in Method → Email/Password**.

4. Create Cloud Firestore in `estroshopstz` if it has not been created.

5. Deploy security rules and indexes:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes --project estroshopstz
   ```

6. Run on a connected Android device:

   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

## Verification

Run static analysis and the automated suite:

```bash
flutter analyze
flutter test
```

Manual Firebase verification still required:

1. Create a new account with Email/Password.
2. Add a sale, expense, debt, debt payment, menu item, ingredient, mishkaki record, sack, personal expense, and personal income.
3. Confirm documents appear under `users/{uid}/...` in Firestore.
4. Sign out and sign back in; confirm the same records reappear.
5. Confirm the app can read and write documents after signup.

## Where things live

| Area | Location |
| --- | --- |
| App entry and Firebase initialization | `lib/main.dart` |
| Routes | `lib/core/router.dart` |
| Theme | `lib/core/theme.dart` |
| Strings | `lib/core/strings.dart` |
| Money/date/aggregation logic | `lib/core/format.dart`, `lib/core/logic.dart` |
| Models | `lib/models/models.dart` |
| Firestore repository and in-memory test repository | `lib/data/repository.dart` |
| Firebase auth and fake auth | `lib/data/auth.dart` |
| Typed Firestore API | `lib/data/store.dart` |
| Auth/data providers | `lib/providers.dart` |
| Shared widgets | `lib/widgets/common.dart` |
| Screens | `lib/screens/` |
| Firestore rules | `firestore.rules` |
| Firestore indexes | `firestore.indexes.json` |
| Firebase CLI config | `firebase.json` |
| Tests | `test/` |
| Logo | `assets/logow.png` |

## Firestore layout

All business and personal data is stored under the signed-in user's document:

```text
users/{uid}/profile/profile
users/{uid}/menuItems/{itemId}
users/{uid}/ingredients/{ingredientId}
users/{uid}/sales/{saleId}
users/{uid}/expenses/{expenseId}
users/{uid}/expenseNames/{nameId}
users/{uid}/mishkaki/{saleId}
users/{uid}/mishkakiStock/{stockId}
users/{uid}/sacks/{sackId}
users/{uid}/debts/{debtId}
users/{uid}/debtPayments/{paymentId}
users/{uid}/personalExpenses/{expenseId}
users/{uid}/personalIncome/{incomeId}
```

Security rules currently allow public read/write for all Firestore documents.

## Business rules

- Sales, expenses, mishkaki, sacks, and debts affect business totals.
- Debt payments count as revenue on the date received.
- Personal income and personal expenses never affect business totals.
- Ingredient costs and `otherCost` are captured on each sale line for historical profit accuracy.
- Money is stored with full precision and displayed as whole Tanzanian shillings.
- Batch entry saves every food item as its own order with its own date, note, sack link and debt.
- Sack profit is revenue minus ingredient cost minus the entered sack price, grouped by the days the sack was used.
- Every screen has a back action; subpages use push navigation so back returns instead of exiting the app.
- The floating bottom bar keeps Home centered and follows the active route.

## Test coverage

- Unit tests: formatting, day keys, revenue/profit totals, debt direction, sack day grouping.
- Widget tests: shared widgets, back-enabled headers, batch order controls and every screen.
- Flow tests: debt payment flow, sample menu seeding, personal/business separation, expense-name usage.

## Completion checklist

| Item | Status |
| --- | --- |
| Flutter project scaffold | Done |
| Dependencies and assets | Done |
| Firebase registration and options | Done |
| Launcher icon and native splash | Done |
| Theme, routing, shared widgets | Done |
| All models and typed Firestore API | Done |
| Email/password auth screens | Done |
| Sales, expenses, menu, ingredients, mishkaki, sacks, debts | Done |
| Analytics charts and reports | Done |
| Profile, personal budget, personal income, expense names | Done |
| Firestore rules and indexes written | Done |
| Static analysis | Done: `No issues found!` |
| Automated tests | Done: 31 tests passed |
| Firestore public rules deployment | Done |
| Live Firebase signup/write/signout/signin verification | Pending |
| iOS simulator verification | Not available on Windows |
