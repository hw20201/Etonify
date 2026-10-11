package com.etonify.meow_client

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.ActivityNotFoundException
import android.os.PowerManager
import android.provider.Settings
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
class BatteryOptimizationSettingsTest {
    class OemActivity : Activity() {
        val attemptedActions = mutableListOf<String>()
        var denyAll = false
        override fun startActivity(intent: Intent) {
            attemptedActions.add(intent.action!!)
            if (denyAll || intent.action != Settings.ACTION_APPLICATION_DETAILS_SETTINGS) {
                throw ActivityNotFoundException("OEM screen missing")
            }
        }
    }

    @Test
    fun `missing battery screens fall back to this app details`() {
        val activity = Robolectric.buildActivity(OemActivity::class.java).setup().get()
        assertTrue(BatteryOptimizationSettings.openSettings(activity))
        assertEquals(listOf(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS,
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS), activity.attemptedActions)
    }

    @Test
    fun `unavailable system screens report failure`() {
        val activity = Robolectric.buildActivity(OemActivity::class.java).setup().get()
        activity.denyAll = true
        assertFalse(BatteryOptimizationSettings.openSettings(activity))
    }
    @Test
    fun `status follows Android exemption instead of a preference`() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val power = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        shadowOf(power).setIgnoringBatteryOptimizations(activity.packageName, false)
        assertEquals("restricted", BatteryOptimizationSettings.getStatus(activity))
        shadowOf(power).setIgnoringBatteryOptimizations(activity.packageName, true)
        assertEquals("exempt", BatteryOptimizationSettings.getStatus(activity))
    }

    @Test
    fun `user request opens exemption dialog for only this package`() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        assertTrue(BatteryOptimizationSettings.openSettings(activity))
        val intent = shadowOf(activity).nextStartedActivity
        assertEquals(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, intent.action)
        assertEquals("package:${activity.packageName}", intent.data.toString())
    }
}
