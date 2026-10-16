package com.jackwallner.skat.ui

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import com.google.android.play.core.review.ReviewManagerFactory
import com.jackwallner.skat.AppGraph
import com.jackwallner.skat.data.AlarmReminderScheduler
import com.jackwallner.skat.ui.nav.LocalNavigator
import com.jackwallner.skat.ui.nav.NavStack
import com.jackwallner.skat.ui.nav.Navigator
import com.jackwallner.skat.ui.nav.Route
import com.jackwallner.skat.ui.nav.SessionPurpose
import com.jackwallner.skat.ui.screens.DrillScreen
import com.jackwallner.skat.ui.screens.EndlessPickerScreen
import com.jackwallner.skat.ui.screens.FeedbackSheet
import com.jackwallner.skat.ui.screens.GameNightPrepScreen
import com.jackwallner.skat.ui.screens.HomeScreen
import com.jackwallner.skat.ui.screens.HowToPlayScreen
import com.jackwallner.skat.ui.screens.SkatMinuteResultScreen
import com.jackwallner.skat.ui.screens.SkatMinuteScreen
import com.jackwallner.skat.ui.screens.OnboardingScreen
import com.jackwallner.skat.ui.screens.PaywallSheet
import com.jackwallner.skat.ui.screens.PracticeRunScreen
import com.jackwallner.skat.ui.screens.RoomScreen
import com.jackwallner.skat.ui.screens.SessionScreen
import com.jackwallner.skat.ui.screens.SettingsScreen
import com.jackwallner.skat.ui.screens.StatsScreen
import com.jackwallner.skat.ui.screens.WhatsNewSheet
import com.jackwallner.skat.ui.screens.gameNightPrepItems
import com.jackwallner.skat.ui.theme.SkatAlert
import com.jackwallner.skat.ui.theme.SkatSheet
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Branches onboarding vs Home on `hasOnboarded` (a branch, never a cover, so
 * Home never flashes behind onboarding), and owns the app-wide sheets.
 */
@Composable
fun RootScreen(graph: AppGraph, pendingRoute: String?, onRouteConsumed: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val navigator = remember { Navigator() }
    var paywallSource by remember { mutableStateOf<String?>(null) }
    var showWhatsNew by remember { mutableStateOf(false) }
    var showFeedback by remember { mutableStateOf(false) }
    var prepAfterUpgrade by remember { mutableStateOf(false) }
    var pendingGrant by remember { mutableStateOf<(() -> Unit)?>(null) }
    val isPro = graph.subscriptions.isPro

    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) pendingGrant?.invoke() else graph.settings.reminderPermissionDenied = true
        pendingGrant = null
    }
    val requestNotifications: (() -> Unit) -> Unit = { onGranted ->
        AlarmReminderScheduler.ensureChannel(context)
        if (AlarmReminderScheduler.canNotify(context)) {
            onGranted()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pendingGrant = onGranted
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    val actions = remember(graph) {
        object : AppActions {
            override fun openPaywall(source: String) {
                paywallSource = source
            }

            override fun openFeedback() {
                showFeedback = true
            }

            override fun openWhatsNew() {
                showWhatsNew = true
            }

            override fun positiveMoment() {
                graph.review.recordPositiveMoment()
                if (!graph.review.shouldShowAfterPositiveMoment()) return
                // Spent when requested, not when answered: Play may show nothing at all.
                graph.review.markStoreCardRequested()
                val activity = context.findActivity() ?: return
                scope.launch {
                    // Let the celebration land first.
                    delay(1_400)
                    val manager = ReviewManagerFactory.create(activity)
                    manager.requestReviewFlow().addOnCompleteListener { request ->
                        if (request.isSuccessful) manager.launchReviewFlow(activity, request.result)
                    }
                }
            }
        }
    }

    // The game-night notification opens the prep session; a lapsed member gets the paywall first.
    // A cold start has isPro false until the customer record loads, so wait for it (or a few
    // seconds offline) rather than sell a member the paywall from their own reminder.
    val membershipResolved = graph.subscriptions.membershipResolved
    var membershipWaitOver by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(4_000)
        membershipWaitOver = true
    }
    LaunchedEffect(pendingRoute, graph.progress.hasOnboarded, membershipResolved, membershipWaitOver) {
        if (pendingRoute != AlarmReminderScheduler.GAME_NIGHT_PREP_VALUE || !graph.progress.hasOnboarded) return@LaunchedEffect
        if (!membershipResolved && !membershipWaitOver) return@LaunchedEffect
        onRouteConsumed()
        if (isPro) {
            navigator.popToRoot()
            navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
        } else {
            prepAfterUpgrade = true
            paywallSource = "skat_home_sheet"
        }
    }
    LaunchedEffect(isPro, membershipResolved) {
        if (isPro && prepAfterUpgrade) {
            prepAfterUpgrade = false
            navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
        } else if (!isPro && membershipResolved && graph.settings.gameNightReminderEnabled) {
            // Only on a customer record that says "not a member". Every launch
            // starts with isPro false, and switching the reminder off then
            // cancelled a paid member's alarm on a slow or offline start.
            graph.settings.updateGameNightReminderEnabled(false)
        }
    }
    LaunchedEffect(graph.progress.hasOnboarded) {
        if (!graph.whatsNew.shouldPresent(graph.progress.hasOnboarded)) return@LaunchedEffect
        delay(500)
        showWhatsNew = true
    }

    CompositionLocalProvider(LocalAppActions provides actions, LocalNavigator provides navigator) {
        AnimatedContent(
            graph.progress.hasOnboarded,
            transitionSpec = { fadeIn(tween(350)) togetherWith fadeOut(tween(350)) },
            label = "root",
        ) { onboarded ->
            if (!onboarded) {
                OnboardingScreen()
            } else {
                NavStack(navigator, enabled = paywallSource == null && !showWhatsNew && !showFeedback) { route ->
                    when (route) {
                        Route.Home -> HomeScreen()
                        is Route.Room -> RoomScreen(route.roomId)
                        is Route.Drill -> DrillScreen(route.roomId, route.drillId)
                        is Route.Session -> SessionScreen(route.items, route.purpose)
                        is Route.Practice -> PracticeRunScreen(route.mode, route.items)
                        Route.SkatMinute -> SkatMinuteScreen()
                        is Route.MinuteResult -> SkatMinuteResultScreen(route.result)
                        Route.GameNightPrep -> GameNightPrepScreen(requestNotifications)
                        Route.EndlessPicker -> EndlessPickerScreen()
                        Route.Stats -> StatsScreen()
                        Route.HowToPlay -> HowToPlayScreen(onDone = { navigator.pop() }, onBack = { navigator.pop() })
                        Route.Settings -> SettingsScreen(requestNotifications)
                    }
                }
            }
        }
        SkatSheet(paywallSource != null, onDismiss = { paywallSource = null; prepAfterUpgrade = false }) {
            PaywallSheet(paywallSource ?: "skat_paywall_sheet", onClose = { paywallSource = null })
        }
        SkatSheet(showWhatsNew, onDismiss = { graph.whatsNew.markSeen(); showWhatsNew = false }) {
            WhatsNewSheet(
                onClose = { showWhatsNew = false },
                onUpgrade = {
                    showWhatsNew = false
                    scope.launch {
                        delay(350)
                        paywallSource = "skat_home_sheet"
                    }
                },
            )
        }
        SkatSheet(showFeedback, onDismiss = { showFeedback = false }) {
            FeedbackSheet(onClose = { showFeedback = false })
        }
        // Raised wherever the request was made (Settings or Game Night Prep),
        // so a denied switch never just silently stays off.
        if (graph.settings.reminderPermissionDenied) {
            SkatAlert(
                "Mitteilungen sind aus",
                "Skat Trainer kann keine Erinnerungen senden, solange Mitteilungen in den Android-Einstellungen aus sind.",
                confirmTitle = "Einstellungen öffnen",
                dismissTitle = "Jetzt nicht",
                onConfirm = {
                    graph.settings.reminderPermissionDenied = false
                    context.startActivity(
                        android.content.Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName),
                    )
                },
                onDismiss = { graph.settings.reminderPermissionDenied = false },
            )
        }
    }
}
