# Context Payload - Flutter Expense Tracker V2

**To the Antigravity assistant reading this at the user's home:**
Hello! We have been aggressively expanding this user's personalized Flutter Finance application. Please review the following architecture notes to get seamlessly up to speed. 

## Architectural Foundation
- **Local Persistence**: We are using `hive_flutter` for blistering fast local storage. The active boxes are `transactions_v2`, `budgets_v2`, and the newly created `subscriptions_v1`!
- **State Management**: We are using `provider`. The `ExpenseProvider` currently maps balances intelligently by scanning `isIncome` markers against `paymentMethod` designations.

## What We Just Finished (Phase 7)
- **Multi-Wallet Ledger**: Balances dynamically filter metrics for three modes: `Main Bank`, `UPI Lite`, and `Cash`. 
- **The Transfer Engine**: In the `AddExpenseForm`, selecting the `Transfer` SegmentedButton seamlessly generates both a mapped negative Expense and a positive Income record between the target wallets simultaneously.
- **Automation Engine**: The `SubscriptionsScreen` maps exact `paymentHour` and `paymentMinute` metrics into a physical `SubscriptionModel`. `ExpenseProvider` is tied to an `AppLifecycle` observer, silently sweeping the internal clock when the app `resumes` from the background, autonomously logging any past-due scheduled payments.
- **CSV Data Portability**: Added `csv` and `path_provider` APIs. The top right icon natively packages all Hive objects into a literal spreadsheet in the user's OS `Downloads` folder.
- **Quality of Life**: We integrated Swipe-to-Delete functionality via `Dismissible` across the transaction lists.

## Next Master Steps (Phase 8)
Proceed to execute whatever the user requests, but prior goals identified included:
1. **App Gating**: Integrating local biometrics (fingerprint/FaceID) or PIN codes to secure financial data.
2. **Category Generation**: Upgrading `CategoryConstants` from a hardcoded list into a customizable dynamic database structure.

*End of payload. Treat the user well!*
