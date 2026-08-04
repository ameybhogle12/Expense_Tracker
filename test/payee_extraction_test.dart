import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/notification_tracker.dart';

/// Regression tests for payee-name extraction from bank / UPI messages.
///
/// The cases below are real-world message shapes. The SVC Bank one is an actual
/// message that previously produced "9820620454" — the STOPUPI helpline number —
/// because the old catch-all regex grabbed the first "to" in the string.
void main() {
  group('extractPayee - real bank formats', () {
    test('SVC Bank NPCI remittance format', () {
      const sms =
          'SVC Bank A/c *2765 DEBITED for Rs.10.00 Clr Bal Rs.5,282.34. '
          'CR UPI/DR/127097027155/AKANKSHA A. Not You? SMS STOPUPI to '
          '9820620454 /Call 18003132120';
      expect(NotificationTracker.extractPayee(sms), 'Akanksha A');
    });

    test('SBI style trf-to with Refno', () {
      const sms =
          'A/c *2765 debited by Rs.10.0 on date 30Jul26 trf to AKANKSHA A '
          'Refno 127097027155. If not you, call 1800111109.';
      expect(NotificationTracker.extractPayee(sms), 'Akanksha A');
    });

    test('amount between verb and "to" (the old blind spot)', () {
      const sms = 'Paid Rs.10 to Akanksha Aher on 30-07-26.';
      expect(NotificationTracker.extractPayee(sms), 'Akanksha Aher');
    });

    test('GPay style short form', () {
      const sms = 'You paid Rs.250 to Swiggy';
      expect(NotificationTracker.extractPayee(sms), 'Swiggy');
    });

    test('VPA handle when no display name is present', () {
      const sms =
          'Rs.10.00 debited from a/c **2765 on 30-07-26 to VPA akanksha@okaxis '
          '(UPI Ref no 127097027155)';
      expect(NotificationTracker.extractPayee(sms), 'Akanksha');
    });

    test('card / POS merchant', () {
      const sms = 'INR 499.00 spent at AMAZON on 30-07-26 via HDFC Card xx2765.';
      expect(NotificationTracker.extractPayee(sms), 'Amazon');
    });
  });

  group('extractPayee - must NOT return junk', () {
    test('returns null rather than a helpline number', () {
      // No payee anywhere; the only "to" is the helpline instruction.
      const sms =
          'A/c *2765 DEBITED for Rs.10.00. Not You? SMS STOPUPI to 9820620454';
      expect(NotificationTracker.extractPayee(sms), isNull);
    });

    test('rejects a bare reference number', () {
      const sms = 'Paid Rs.10 to 127097027155 on 30-07-26.';
      expect(NotificationTracker.extractPayee(sms), isNull);
    });

    test('rejects bank boilerplate as a name', () {
      const sms = 'Rs.10 debited to your account on 30-07-26.';
      expect(NotificationTracker.extractPayee(sms), isNull);
    });
  });

  group('formatting', () {
    test('shouty bank casing is normalised', () {
      const sms = 'UPI/DR/127097027155/RAJESH KUMAR SHARMA.';
      expect(NotificationTracker.extractPayee(sms), 'Rajesh Kumar Sharma');
    });
  });

  // Cases observed on-device on 2026-08-01.
  group('isTransactionMessage - real misses and false positives', () {
    const gpay = 'com.google.android.apps.nbu.paisa.user';
    const messages = 'com.google.android.apps.messaging';

    test('Indian Bank "Sent Rs.X ... to PAYEE" is detected as expense', () {
      // Previously missed entirely: the trigger list wanted the contiguous
      // phrase "sent to", but the amount and account sit in between.
      const sms =
          'Sent Rs.40.00 from A/c *6394 on 01-08-26 to MUMBAI METRO ONE.'
          'RRN 657900820238.Avl Bal Rs.3042.16.Not you?SMS BLOCK to '
          '9289592895-Indian Bank';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isFalse);
      expect(NotificationTracker.extractPayee(sms), 'Mumbai Metro One');
    });

    test('GPay bill-due reminder is NOT a payment', () {
      // Previously logged as a spend: known finance package + contains a digit.
      const text =
          'Due date for Adani Electricity bill approaching '
          'Rs.250.00 due on Aug 5, 2026.';
      expect(NotificationTracker.isTransactionMessage(text, gpay), isNull);
    });

    test('SVC Bank debit is detected as expense', () {
      const sms =
          'SVC Bank A/c *2765 DEBITED for Rs.10.00 Clr Bal Rs.5,282.34. '
          'CR UPI/DR/127097027155/AKANKSHA A. Not You? SMS STOPUPI to '
          '9820620454 /Call 18003132120';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isFalse);
    });

    test('incoming credit is detected as income', () {
      const sms = 'A/c *6394 credited with Rs.500.00 on 01-08-26.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isTrue);
    });

    test('"paid via credit card" is still a spend, not a credit', () {
      // The old substring check matched "credit" inside "credit card".
      const sms = 'Rs.500.00 paid at AMAZON via credit card on 01-08-26.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isFalse);
    });

    test('payment request is not a completed payment', () {
      const text = 'Akanksha is requesting Rs.250.00';
      expect(NotificationTracker.isTransactionMessage(text, gpay), isNull);
    });

    test('failed payment is not logged', () {
      const sms = 'Your payment of Rs.250.00 to Zepto failed.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isNull);
    });

    test('OTP is never a payment', () {
      const sms = 'Your OTP for txn of Rs.500 is 123456.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isNull);
    });
  });

  group('isTransactionMessage - income detection', () {
    const messages = 'com.google.android.apps.messaging';

    test('simple credit is detected as income', () {
      const sms = 'A/c *2765 is CREDITED for Rs 5,600.00.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isTrue);
    });

    test('received money is income', () {
      const sms = 'You received Rs.5,000.00 from Rahul on 02-08-26.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isTrue);
    });

    test('refund is income', () {
      const sms = 'Refund of Rs.250.00 processed to your a/c on 02-08-26.';
      expect(NotificationTracker.isTransactionMessage(sms, messages), isTrue);
    });
  });
}
