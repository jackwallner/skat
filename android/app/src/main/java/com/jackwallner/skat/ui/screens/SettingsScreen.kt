package com.jackwallner.skat.ui.screens

import androidx.compose.material3.TextButton

import androidx.compose.material3.OutlinedTextFieldDefaults

import androidx.compose.material3.OutlinedTextField

import androidx.compose.material3.AlertDialog

import androidx.compose.foundation.combinedClickable

import androidx.compose.foundation.ExperimentalFoundationApi

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.skat.BuildConfig
import com.jackwallner.skat.data.Appearance
import com.jackwallner.skat.data.Membership
import com.jackwallner.skat.data.PurchaseException
import com.jackwallner.skat.data.StoreLinks
import com.jackwallner.skat.ui.LocalAppActions
import com.jackwallner.skat.ui.LocalGraph
import com.jackwallner.skat.ui.components.symbol
import com.jackwallner.skat.ui.nav.LocalNavigator
import com.jackwallner.skat.ui.nav.Route
import com.jackwallner.skat.ui.openFeedbackMail
import com.jackwallner.skat.ui.openPlayListing
import com.jackwallner.skat.ui.openUrl
import com.jackwallner.skat.ui.theme.BarTextButton
import com.jackwallner.skat.ui.theme.FormDivider
import com.jackwallner.skat.ui.theme.FormRow
import com.jackwallner.skat.ui.theme.FormSection
import com.jackwallner.skat.ui.theme.Haptics
import com.jackwallner.skat.ui.theme.IconBadge
import com.jackwallner.skat.ui.theme.Skat
import com.jackwallner.skat.ui.theme.SkatAlert
import com.jackwallner.skat.ui.theme.SkatBar
import com.jackwallner.skat.ui.theme.SkatScreen
import com.jackwallner.skat.ui.theme.SkatSwitch
import com.jackwallner.skat.ui.theme.SkatType
import com.jackwallner.skat.ui.theme.PrimaryCTA
import com.jackwallner.skat.ui.theme.PlusBadge
import com.jackwallner.skat.ui.theme.Readable
import com.jackwallner.skat.ui.theme.Segmented
import com.jackwallner.skat.ui.theme.TimePickerRow
import com.jackwallner.skat.ui.theme.navBarPadding
import com.jackwallner.skat.ui.theme.pressable
import com.jackwallner.skat.ui.theme.QuietButton
import com.jackwallner.skat.ui.theme.themedCard
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val actions = LocalAppActions.current
    val context = LocalContext.current
    val colors = Skat.colors
    val scope = rememberCoroutineScope()
    val settings = graph.settings
    val service = graph.subscriptions
    var restoreMessage by remember { mutableStateOf<String?>(null) }
    var confirmReset by remember { mutableStateOf(false) }
    var showReviewerCode by remember { mutableStateOf(false) }

    SkatScreen("Einstellungen", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                FormSection("Darstellung") {
                    Box(Modifier.padding(12.dp)) {
                        Segmented(Appearance.entries, settings.appearance, { it.displayName }) { settings.updateAppearance(it) }
                    }
                }
                FormSection("Üben") {
                    FormRow("Haptisches Feedback") { SkatSwitch(settings.hapticsEnabled, "Haptisches Feedback") { settings.updateHaptics(it) } }
                    FormDivider()
                    FormRow("Töne") { SkatSwitch(settings.soundEnabled, "Töne") { settings.updateSound(it) } }
                    FormDivider()
                    FormRow("Tägliche Erinnerung") {
                        SkatSwitch(settings.reminderEnabled, "Tägliche Erinnerung") { on ->
                            if (on) requestNotifications { settings.updateReminderEnabled(true) } else settings.updateReminderEnabled(false)
                        }
                    }
                    if (settings.reminderEnabled) {
                        FormDivider()
                        Box(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                            TimePickerRow("Erinnerungszeit", settings.reminderHour, settings.reminderMinute) { h, m -> settings.updateReminderTime(h, m) }
                        }
                    }
                    if (service.isPro) {
                        FormDivider()
                        FormRow("Skatabend-Vorbereitung", icon = "person.2.fill", onClick = { navigator.push(Route.GameNightPrep) }) { Chevron() }
                    }
                }
                FormSection("Mitgliedschaft") {
                    if (service.isPro) {
                        FormRow("${Membership.NAME} freigeschaltet", icon = "checkmark.seal.fill", tint = colors.jade)
                        FormDivider()
                        FormRow("Abonnement verwalten", onClick = { context.openUrl(StoreLinks.manageSubscriptionURL(service.activeProductId)) }) { Chevron() }
                    } else {
                        FormRow("${Membership.NAME} entdecken", icon = "sparkles", onClick = { actions.openPaywall("skat_settings_sheet") }) { PlusBadge() }
                    }
                    FormDivider()
                    FormRow("Käufe wiederherstellen", tint = colors.jade, onClick = {
                        scope.launch {
                            restoreMessage = try {
                                service.restore()
                                if (service.isPro) "${Membership.NAME} wurde wiederhergestellt." else "Für dieses Google-Konto wurde kein früherer Kauf gefunden."
                            } catch (error: PurchaseException) {
                                error.message
                            }
                        }
                    })
                }
                FormSection("Deine Übungshistorie") {
                    FormRow("Dein Fortschritt", icon = "chart.bar.fill", onClick = { navigator.push(Route.Stats) }) { Chevron() }
                    FormDivider()
                    FormRow("Fortschritt zurücksetzen", tint = colors.crakRed, onClick = { confirmReset = true })
                }
                FormSection("Hilfe") {
                    FormDivider()
                    FormRow("So geht Skat", icon = "book.fill", onClick = { navigator.push(Route.HowToPlay) }) { Chevron() }
                    if (graph.whatsNew.currentRelease != null) {
                        FormDivider()
                        FormRow("Neu in dieser Version", icon = "sparkle", onClick = { actions.openWhatsNew() })
                    }
                    FormDivider()
                    FormRow("Skat Trainer bewerten", icon = "star.fill", onClick = {
                        graph.review.markOpenedWriteReview()
                        context.openPlayListing()
                    })
                    FormDivider()
                    FormRow("Feedback senden", icon = "envelope.fill", onClick = { actions.openFeedback() })
                }
                FormSection("Über Skat Trainer") {
                    // Long press opens the private reviewer access for Google Play's review team.
                    FormRow(
                        "Version",
                        Modifier.testTag("version-row").combinedClickable(onClick = {}, onLongClick = { showReviewerCode = true }),
                    ) { Text(BuildConfig.VERSION_NAME, style = SkatType.body, color = colors.inkSecondary) }
                    FormDivider()
                    Text(
                        "Skat Trainer ist eine unabhängige Übungs-App mit eigenen Lehrbeispielen. Regeln können am Tisch variieren, spiele nach den Regeln, die ihr vereinbart habt.",
                        style = SkatType.footnote,
                        color = colors.inkSecondary,
                        modifier = Modifier.padding(16.dp),
                    )
                }
                if (BuildConfig.DEBUG) {
                    FormSection("Entwicklung") {
                        FormRow("Lokale Mitgliedschaft aktivieren") {
                            SkatSwitch(service.isPro, "Lokale Mitgliedschaft") { service.setLocalOverride(it) }
                        }
                    }
                }
            }
        }
    }

    restoreMessage?.let { SkatAlert("Wiederherstellen", it, onConfirm = { restoreMessage = null }) }
    if (showReviewerCode) ReviewerCodeDialog { showReviewerCode = false }
    if (confirmReset) {
        SkatAlert(
            "Fortschritt zurücksetzen?",
            "Deine Serie, abgeschlossenen Übungen und Übungshistorie werden gelöscht. Käufe bleiben erhalten.",
            confirmTitle = "Zurücksetzen",
            destructive = true,
            dismissTitle = "Abbrechen",
            onConfirm = {
                confirmReset = false
                graph.resetProgress()
            },
            onDismiss = { confirmReset = false },
        )
    }
    // The "Notifications are off" alert lives in RootScreen, next to the
    // permission request, so Game Night Prep gets it too.
}

/** Private unlock for Google Play's review team; only the code's SHA-256 ships in the app. */
@Composable
private fun ReviewerCodeDialog(onDismiss: () -> Unit) {
    val service = LocalGraph.current.subscriptions
    val colors = Skat.colors
    var code by remember { mutableStateOf("") }
    var failed by remember { mutableStateOf(false) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = colors.card,
        titleContentColor = colors.ink,
        title = { Text("Zugang für Prüfer", style = SkatType.headline) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Gib den Prüfercode aus den Hinweisen zur App-Prüfung ein.", style = SkatType.subheadline, color = colors.inkSecondary)
                OutlinedTextField(
                    code,
                    { code = it; failed = false },
                    singleLine = true,
                    textStyle = SkatType.body.copy(color = colors.ink),
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = colors.jade, unfocusedBorderColor = colors.rule, cursorColor = colors.jade),
                    modifier = Modifier.testTag("reviewer-code"),
                )
                if (failed) Text("Dieser Code ist ungültig.", style = SkatType.caption, color = colors.crakRed)
            }
        },
        confirmButton = {
            TextButton(onClick = { if (service.activateReviewAccess(code)) onDismiss() else failed = true }, modifier = Modifier.testTag("reviewer-unlock")) {
                Text("Freischalten", style = SkatType.headline, color = colors.jade)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Abbrechen", style = SkatType.body, color = colors.inkSecondary) } },
    )
}

@Composable
private fun Chevron() {
    Icon(symbol("chevron.right"), null, tint = Skat.colors.inkTertiary, modifier = Modifier.size(18.dp))
}

/**
 * Shown once on the first launch after an update: what a member already owns,
 * or what the membership would add. One dismiss, at most one soft upgrade.
 */
@Composable
fun WhatsNewSheet(onClose: () -> Unit, onUpgrade: () -> Unit) {
    val graph = LocalGraph.current
    val colors = Skat.colors
    val release = graph.whatsNew.currentRelease ?: return
    val isPro = graph.subscriptions.isPro
    val hasLocked = !isPro && release.items.any { it.isPlus }
    fun close() {
        graph.whatsNew.markSeen()
        onClose()
    }
    Column(Modifier.fillMaxSize()) {
        SkatBar("", onBack = null, trailing = { BarTextButton("Fertig", colors.inkSecondary) { close() } }, inSheet = true)
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("NEU IN DIESER VERSION", style = SkatType.eyebrow, color = colors.inkSecondary)
                Text(release.headline, style = SkatType.display(30.sp), color = colors.ink)
                Text("Version ${release.version}", style = SkatType.footnote, color = colors.inkTertiary)
            }
            release.items.forEach { item ->
                val locked = item.isPlus && !isPro
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    IconBadge(item.icon, if (locked) colors.gold else colors.jade, size = 42.dp, iconSize = 22.dp, corner = 13.dp)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text(item.title, style = SkatType.headline, color = colors.ink)
                            if (locked) PlusBadge()
                        }
                        Text(item.body, style = SkatType.subheadline, color = colors.inkSecondary)
                    }
                }
            }
        }
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 10.dp).padding(navBarPadding(0.dp)), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (hasLocked) {
                PrimaryCTA("Mit ${Membership.NAME} freischalten", color = colors.gold) {
                    graph.whatsNew.markSeen()
                    onUpgrade()
                }
                QuietButton("Kostenlos weiterüben", Modifier.fillMaxWidth()) { close() }
            } else {
                PrimaryCTA("Übung starten") { close() }
            }
        }
    }
}

/** Feedback goes to a real person through the mail app, and only claims success if one opened. */
@Composable
fun FeedbackSheet(onClose: () -> Unit) {
    val graph = LocalGraph.current
    val context = LocalContext.current
    val clipboard: ClipboardManager = LocalClipboardManager.current
    val colors = Skat.colors
    var text by remember { mutableStateOf("") }
    var mailFailed by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    val trimmed = text.trim()
    Column(Modifier.fillMaxSize()) {
        SkatBar("Hilf uns, besser zu werden", onBack = null, leading = { BarTextButton("Abbrechen", colors.inkSecondary, onClick = onClose) }, inSheet = true)
        Column(Modifier.weight(1f).padding(24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("Was würde Skat Trainer für dich besser machen?", style = SkatType.headline, color = colors.ink)
            BasicTextField(
                text,
                { text = it },
                textStyle = SkatType.body.copy(color = colors.ink),
                cursorBrush = SolidColor(colors.jade),
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f, fill = false)
                    .testTag("feedback-text")
                    .focusRequester(focus)
                    .themedCard(14.dp)
                    .padding(12.dp),
                minLines = 6,
            )
            if (mailFailed) {
                // Plenty of people have no mail app set up; say so rather than claim it sent.
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Deine Mail-App wurde nicht geöffnet. Du kannst uns direkt schreiben:", style = SkatType.caption, color = colors.ink)
                    Row(
                        Modifier.testTag("copy-email").pressable {
                            clipboard.setText(AnnotatedString(StoreLinks.FEEDBACK_EMAIL))
                            Haptics.success()
                        }.padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(symbol("doc.on.doc"), null, tint = colors.jade, modifier = Modifier.size(14.dp))
                        Text("${StoreLinks.FEEDBACK_EMAIL} kopieren", style = SkatType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.jade)
                    }
                }
            } else {
                Text("Öffnet deine Mail-App mit einem Entwurf an den Entwickler. Die Nachricht geht an eine echte Person.", style = SkatType.caption, color = colors.inkSecondary)
            }
            PrimaryCTA("Feedback senden", Modifier.testTag("send-feedback"), enabled = trimmed.isNotEmpty()) {
                if (context.openFeedbackMail(trimmed)) {
                    onClose()
                } else {
                    mailFailed = true
                }
            }
        }
    }
}
