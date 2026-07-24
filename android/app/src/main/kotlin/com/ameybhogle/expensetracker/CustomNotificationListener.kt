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

        // Exclude credit/income keywords (only track expenses)
        val creditTriggers = listOf("credited", "received", "refund", "deposited", "added", "credit")
        for (trigger in creditTriggers) {
            if (lowerText.contains(trigger)) return false
        }

        // Check for common financial package names
        val knownFinPackages = listOf(
            "com.google.android.apps.nbu.paisa.user", // GPay
            "net.one97.paytm", // Paytm
            "com.phonepe.app", // PhonePe
            "in.org.npci.upiapp" // BHIM
        )

        if (knownFinPackages.contains(packageName)) {
            if (!lowerText.contains("otp") && !lowerText.contains("code") && !lowerText.contains("verification")) {
                // Must contain at least a digit
                return lowerText.any { it.isDigit() }
            }
            return false
        }

        // Keyword checks
        val triggers = listOf(
            "debited",
            "sent to",
            "paid to",
            "spent",
            "txn",
            "transaction",
            "payment of",
            "withdrawn"
        )

        for (trigger in triggers) {
            if (lowerText.contains(trigger)) {
                if (!lowerText.contains("otp") && !lowerText.contains("code") && !lowerText.contains("verification")) {
                    return true
                }
            }
        }

        return false
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

        var merchant: String? = null
        val merchantRegexes = listOf(
            Pattern.compile("(?:paid|sent|transferred)\\s+to\\s+([^.]+?)(?:\\s+on|\\s+using|\\s+at|\\s+from|\\s+ref|\\.)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("at\\s+([^.]+?)(?:\\s+on|\\s+using|\\s+from|\\s+ref|\\.)", Pattern.CASE_INSENSITIVE),
            Pattern.compile("debited\\s+to\\s+([^.]+?)(?:\\s+on|\\s+using|\\s+from|\\s+ref|\\.)", Pattern.CASE_INSENSITIVE)
        )

        for (pattern in merchantRegexes) {
            val merchantMatcher = pattern.matcher(text)
            if (merchantMatcher.find()) {
                val rawMerchant = merchantMatcher.group(1)?.trim()
                if (!rawMerchant.isNullOrEmpty() && rawMerchant.length < 50) {
                    if (!rawMerchant.lowercase().contains("your account") &&
                        !rawMerchant.lowercase().contains("a/c")) {
                        merchant = rawMerchant
                        break
                    }
                }
            }
        }

        if (merchant == null) {
            val fallbackPattern = Pattern.compile("(?:to|at)\\s+([A-Za-z0-9\\s&]{3,20})", Pattern.CASE_INSENSITIVE)
            val fallbackMatcher = fallbackPattern.matcher(text)
            if (fallbackMatcher.find()) {
                merchant = fallbackMatcher.group(1)?.trim()
            }
        }

        return ParsedTx(amount, merchant ?: "Merchant", currencySymbol)
    }

    private fun showPaymentNotification(amount: Double, merchant: String, currencySymbol: String) {
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

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(com.ameybhogle.expensetracker.R.mipmap.launcher_icon)
            .setContentTitle("💳 Payment Detected")
            .setContentText("Spent $currencySymbol$formattedAmount at $merchant? Tap to log it before you forget!")
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    data class ParsedTx(val amount: Double, val merchant: String, val currencySymbol: String)
}
