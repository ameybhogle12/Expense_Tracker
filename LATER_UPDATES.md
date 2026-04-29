# Later Updates — Expense Tracker

## 1. SMS Auto-Logging via Inbox Polling

**Status:** On Hold  
**Priority:** Medium  
**Last Worked On:** April 21, 2026

### Summary
Automatically log bank transactions (UPI debits, etc.) by reading incoming SMS messages.

### What Was Built
- `lib/services/sms_processor.dart` — Regex engine that parses bank SMS bodies for amounts.
- `telephony` package installed and configured in `pubspec.yaml`.
- `AndroidManifest.xml` has `RECEIVE_SMS`, `READ_SMS` permissions and `IncomingSmsReceiver` registered.
- Background handler (`backgroundMessageHandler`) in `main.dart`.
- SMS listener initialization in `lib/screens/auth_wrapper.dart`.

### What Didn't Work
The `Telephony.SMS_RECEIVED` Broadcast Receiver is unreliable on modern Android 14 devices, especially Realme UI / ColorOS which aggressively kills background receivers. The listener worked sporadically (once from a friend's SMS) but failed consistently in repeated tests.

### Planned Fix: Pivot to Inbox Polling
Instead of relying on the broken Broadcast Receiver, switch to **passive inbox polling**:
1. Store a `lastSmsScanTimestamp` in Hive settings.
2. Every 60s (foreground) or 15min (background via Workmanager), call `Telephony.instance.getInboxSms()` filtering by date > timestamp.
3. Parse matching messages through the existing Regex engine.
4. Update the timestamp to prevent duplicate entries.

### Files to Modify When Resuming
- `lib/services/sms_processor.dart` — Add `scanInbox()` method.
- `lib/providers/expense_provider.dart` — Call `scanInbox()` in the 1-minute timer.
- `lib/services/log_processor.dart` — Call `scanInbox()` in the Workmanager task.
- `lib/screens/auth_wrapper.dart` — Remove broken `listenIncomingSms`, keep permission request.

---

*Add future update ideas below this line.*
