package com.ameybhogle.expensetracker

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.ameybhogle.expensetracker/payment_detection"
    private var methodChannel: MethodChannel? = null
    private var pendingAmount: Double? = null
    private var pendingMerchant: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingNotificationData" -> {
                    if (pendingAmount != null) {
                        val data = mapOf(
                            "amount" to pendingAmount,
                            "merchant" to pendingMerchant
                        )
                        result.success(data)
                        // Clear the pending data so it doesn't get processed again
                        pendingAmount = null
                        pendingMerchant = null
                    } else {
                        result.success(null)
                    }
                }
                "setEnableAutoLogging" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val sharedPrefs = getSharedPreferences("ExpenseTrackerPrefs", Context.MODE_PRIVATE)
                    sharedPrefs.edit().putBoolean("enable_auto_logging", enabled).apply()
                    result.success(true)
                }
                "isBatteryOptimized" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = pm.isIgnoringBatteryOptimizations(packageName)
                        result.success(!isIgnoring) // true = optimized (bad), false = whitelisted (good)
                    } else {
                        result.success(false) // Pre-M: no battery optimization
                    }
                }
                "requestBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback: open general battery optimization settings
                            try {
                                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.success(false)
                            }
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.hasExtra("amount")) {
            val amount = intent.getDoubleExtra("amount", 0.0)
            val merchant = intent.getStringExtra("merchant") ?: "Merchant"
            
            // Store it in case Flutter is not yet initialized or active
            pendingAmount = amount
            pendingMerchant = merchant

            // If MethodChannel is already active, invoke the method directly
            methodChannel?.let { channel ->
                val data = mapOf(
                    "amount" to amount,
                    "merchant" to merchant
                )
                channel.invokeMethod("onPaymentDetected", data)
                // Clear since we already sent it
                pendingAmount = null
                pendingMerchant = null
            }
        }
    }
}

