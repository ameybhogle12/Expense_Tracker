package com.ameybhogle.expensetracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import notification.listener.service.NotificationListener
import java.util.regex.Pattern

class CustomNotificationListener : NotificationListener() {

    companion object {
        private const val TAG = "CustomNotifListener"
        private const val CHANNEL_ID = "payment_detection_channel"
        private const val NOTIFICATION_ID = 1001
        
        // Cooldown mechanism to prevent duplicate notifications
        private val recentTransactions = HashMap<String, Long>()
        private const val COOLDOWN_MS = 60000L // 60 seconds
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // First run the super implementation so the plugin's EventChannel
        // gets the event if the app/Flutter engine is active.
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        if (packageName == "com.ameybhogle.expensetracker") return // Ignore own notifications

        val extras = sbn.notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        val textToParse = "$title $text"
        Log.d(TAG, "Notification received from $packageName: $textToParse")

        if (isTransactionMessage(textToParse, packageName)) {
            val parsed = parseTransaction(textToParse)
            if (parsed != null && parsed.amount > 0) {
                // Check if auto-logging is globally enabled (develop branch / premium version handles auto-logging)
                val sharedPrefs = applicationContext.getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)
                val enableAutoLogging = sharedPrefs.getBoolean("enable_auto_logging", false)
                if (enableAutoLogging) {
                    Log.d(TAG, "Auto-logging is enabled. Native manual notification skipped.")
                    return
                }

                val now = System.currentTimeMillis()
                val dedupeKey = "${parsed.amount}|${parsed.merchant}"
                val lastSeen = recentTransactions[dedupeKey]
                if (lastSeen != null && (now - lastSeen) < COOLDOWN_MS) {
                    Log.d(TAG, "Duplicate transaction ignored: $dedupeKey")
                    return
                }
                recentTransactions[dedupeKey] = now

                // Clean up old cooldown entries
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    recentTransactions.entries.removeIf { now - it.value > 300000L } // 5 minutes
                } else {
                    val iterator = recentTransactions.entries.iterator()
                    while (iterator.hasNext()) {
                        if (now - iterator.next().value > 300000L) {
                            iterator.remove()
                        }
                    }
                }

                Log.d(TAG, "Payment detected: Spent ${parsed.currencySymbol}${parsed.amount} at ${parsed.merchant}")
                showPaymentNotification(parsed.amount, parsed.merchant, parsed.currencySymbol)
            }
        }
    }

    private fun isTransactionMessage(text: String, packageName: String): Boolean {
        val lowerText = text.lowercase()

        // 1. A reminder, request, offer or failure is not a completed spend.
        //    This is checked first and applies to every package. GPay pushes
        //    bill-due reminders that carry an amount ("Due date for Adani
        //    Electricity bill approaching / Rs.250.00 due on Aug 5, 2026"), and
        //    the old rule — known finance package + contains any digit — logged
        //    those as real payments.
        val notAPayment = listOf(
            "due date", "is due", "due on", "due by", "upcoming", "reminder",
            "will be debited", "will be deducted", "scheduled", "autopay",
            "requesting", "has requested", "payment request", "collect request",
            "failed", "declined", "unsuccessful", "cancelled", "reversed",
            "offer", "cashback", "reward", "scratch card", "you won", "voucher",
            "otp", "code", "verification", "verify"
        )
        if (notAPayment.any { lowerText.contains(it) }) return false

        // 2. Money coming in is not a spend. Word-bounded so that a genuine
        //    "paid Rs.500 via credit card" is not mistaken for a credit.
        val creditTriggers = listOf("credited", "received", "refund", "deposited", "added")
        if (creditTriggers.any { Regex("\\b$it").containsMatchIn(lowerText) }) return false

        // 3. Require evidence of a completed outgoing payment.
        //    The amount routinely sits between the verb and the payee — e.g.
        //    "Sent Rs.40.00 from A/c *6394 on 01-08-26 to MUMBAI METRO ONE" —
        //    so matching the contiguous phrase "sent to" misses real debits.
        //    That exact Indian Bank format produced no notification at all.
        val debitVerb = Regex("\\b(?:debited|withdrawn|paid|sent|spent|transferred|trf)\\b")
        if (debitVerb.containsMatchIn(lowerText)) return true

        // Some issuers only ever say "txn" / "transaction" / "payment of".
        return listOf("txn", "transaction", "payment of").any { lowerText.contains(it) }
    }

    private fun parseTransaction(text: String): ParsedTx? {
        // Regex to match amount and currency prefix
        // Matches: ₹500, Rs. 500, Rs 500, INR 500, $, etc.
        val amountPattern = Pattern.compile("(₹|Rs\\.?|INR|\\$)\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)", Pattern.CASE_INSENSITIVE)
        val matcher = amountPattern.matcher(text)
        if (!matcher.find()) return null

        val currencySymbol = matcher.group(1) ?: "₹"
        val amountStr = matcher.group(2)?.replace(",", "") ?: ""
        val amount = amountStr.toDoubleOrNull() ?: return null

        return ParsedTx(amount, extractPayee(text), currencySymbol)
    }

    /**
     * Pulls a human-readable payee name out of a transaction message.
     *
     * Bank SMS formats vary, so this runs an ordered list of patterns — most
     * specific first — and returns the first candidate that actually looks like
     * a name.
     *
     * Returning null is a deliberate, valid outcome. The previous catch-all
     * regex "(to|at) <anything>" grabbed the first "to" anywhere in the string,
     * which on a real SVC Bank message meant the STOPUPI helpline number rather
     * than the payee. Showing no name is strictly better than showing a wrong
     * one, so anything that fails [isPlausibleName] is dropped.
     */
    private fun extractPayee(text: String): String? {
        val patterns = listOf(
            // NPCI remittance format, passed through by most Indian banks:
            //   "... CR UPI/DR/127097027155/AKANKSHA A."
            Pattern.compile("""UPI[/-](?:DR|CR)[/-]\d+[/-]([A-Za-z][A-Za-z\s]{1,39}?)(?=[.,/]|\s+(?:Ref|Not|SMS|Call)|$)""", Pattern.CASE_INSENSITIVE),
            // SBI style: "... trf to AKANKSHA A Refno 127097027155"
            Pattern.compile("""(?:trf|transfer(?:red)?)\s+to\s+([A-Za-z][A-Za-z\s]{1,39}?)(?=\s+(?:refno|ref|on\s+\d|on\s+date|via|using|upi)|[.,]|$)""", Pattern.CASE_INSENSITIVE),
            // "Paid Rs.10 to Akanksha Aher on 30-07" — the amount sits between
            // the verb and "to", which a literal "paid to" match cannot catch.
            Pattern.compile("""(?:paid|sent|debited)\b.{0,40}?\bto\s+([A-Za-z][A-Za-z\s]{1,39}?)(?=\s+(?:refno|ref|on\s+\d|on\s+date|via|using|upi)|[.,?]|$)""", Pattern.CASE_INSENSITIVE),
            // "... to VPA akanksha@okaxis" — fall back to the handle's local part
            Pattern.compile("""VPA\s+([\w.\-]+)@[\w]+""", Pattern.CASE_INSENSITIVE),
            // Card / POS: "spent Rs.500 at AMAZON on 30-07"
            Pattern.compile("""\bat\s+([A-Za-z][A-Za-z0-9\s&.\-]{2,39}?)(?=\s+(?:on\s+\d|on\s+date|ref|using|via)|[.,]|$)""", Pattern.CASE_INSENSITIVE)
        )

        for (pattern in patterns) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val candidate = matcher.group(1)?.trim()?.trim('.', ',', '-')
                if (!candidate.isNullOrEmpty() && isPlausibleName(candidate)) {
                    return toTitleCase(candidate)
                }
            }
        }
        return null
    }

    /** Rejects reference numbers, helpline numbers and bank boilerplate. */
    private fun isPlausibleName(candidate: String): Boolean {
        if (candidate.length < 3 || candidate.length > 40) return false

        val letters = candidate.count { it.isLetter() }
        val digits = candidate.count { it.isDigit() }
        if (letters < 2 || digits > letters) return false

        val lower = candidate.lowercase()
        val noise = listOf(
            "your account", "a/c", "account", "bank", "upi", "vpa", "call",
            "sms", "stopupi", "not you", "avl bal", "clr bal", "bal"
        )
        return noise.none { lower == it || lower.startsWith("$it ") }
    }

    /** "AKANKSHA A" -> "Akanksha A", so the notification doesn't shout. */
    private fun toTitleCase(raw: String): String =
        raw.split(Regex("\\s+")).joinToString(" ") { word ->
            if (word.length <= 1) word.uppercase()
            else word[0].uppercase() + word.substring(1).lowercase()
        }

    private fun showPaymentNotification(amount: Double, merchant: String?, currencySymbol: String) {
        val context = applicationContext
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Payment Detection",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for detected UPI and card payments"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Intent to launch MainActivity and pass extras
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("amount", amount)
            putExtra("merchant", merchant)
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(context, 102, intent, pendingIntentFlags)

        val formattedAmount = if (amount == amount.toInt().toDouble()) {
            String.format("%.0f", amount)
        } else {
            String.format("%.2f", amount)
        }

        // Only name the payee when one was actually recognised — see extractPayee.
        val contentText = if (merchant != null) {
            "Paid $currencySymbol$formattedAmount to $merchant? Tap to log it before you forget!"
        } else {
            "Spent $currencySymbol$formattedAmount? Tap to log it before you forget!"
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(com.ameybhogle.expensetracker.R.mipmap.launcher_icon)
            .setContentTitle("💳 Payment Detected")
            .setContentText(contentText)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    /** [merchant] is null when no name could be confidently extracted. */
    data class ParsedTx(val amount: Double, val merchant: String?, val currencySymbol: String)
}
