package com.etonify.meow_client

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings

/** Android owns this setting. A denied request must never be saved as enabled. */
object BatteryOptimizationSettings {
    fun getStatus(context: Context): String = runCatching {
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return "unavailable"
        if (power.isIgnoringBatteryOptimizations(context.packageName)) "exempt" else "restricted"
    }.getOrDefault("unavailable")

    fun openSettings(activity: Activity): Boolean {
        val packageUri = Uri.parse("package:${activity.packageName}")
        val intents = if (getStatus(activity) == "restricted") {
            listOf(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, packageUri),
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri),
            )
        } else {
            listOf(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri),
            )
        }
        for (intent in intents) {
            try {
                activity.startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                // OEMs may omit the standard battery screen.
            } catch (_: SecurityException) {
                // Try a screen this firmware allows us to open.
            }
        }
        return false
    }
}
