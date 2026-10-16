package com.jackwallner.skat

import android.content.Context
import com.jackwallner.skat.data.AlarmReminderScheduler
import com.jackwallner.skat.data.AppClock
import com.jackwallner.skat.data.AppSettings
import com.jackwallner.skat.data.ConversionDiagnostics
import com.jackwallner.skat.data.SkatMinuteStore
import com.jackwallner.skat.data.PracticeRecordStore
import com.jackwallner.skat.data.ProgressStore
import com.jackwallner.skat.data.ReviewPromptTracker
import com.jackwallner.skat.data.SharedPreferencesStore
import com.jackwallner.skat.data.SubscriptionService
import com.jackwallner.skat.data.WhatsNewTracker
import kotlinx.coroutines.MainScope

/** Every long-lived object the screens share, built once per process. */
class AppGraph(context: Context) {
    val appContext: Context = context.applicationContext
    val scope = MainScope()
    val clock = AppClock()
    val defaults = SharedPreferencesStore(appContext)
    val settings = AppSettings(defaults, AlarmReminderScheduler(appContext))
    val progress = ProgressStore(defaults, clock)
    val records = PracticeRecordStore(defaults, clock)
    val minutes = SkatMinuteStore(defaults, clock)
    val review = ReviewPromptTracker(defaults, clock)
    val diagnostics = ConversionDiagnostics(defaults, clock)
    val subscriptions = SubscriptionService(appContext, defaults, diagnostics)
    val whatsNew = WhatsNewTracker(defaults, BuildConfig.VERSION_NAME)

    /** Settings' Reset Progress: every practice stat, never onboarding or purchases. */
    fun resetProgress() {
        progress.resetAll()
        records.resetAll()
        minutes.resetAll()
    }
}
