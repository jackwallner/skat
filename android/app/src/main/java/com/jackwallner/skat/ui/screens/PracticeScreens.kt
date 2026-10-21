package com.jackwallner.skat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.skat.content.DrillLibrary
import com.jackwallner.skat.content.PracticeSkill
import com.jackwallner.skat.content.SessionBuilder
import com.jackwallner.skat.data.PracticeRecordStore
import com.jackwallner.skat.ui.LocalGraph
import com.jackwallner.skat.ui.components.symbol
import com.jackwallner.skat.ui.nav.LocalNavigator
import com.jackwallner.skat.ui.nav.PracticeMode
import com.jackwallner.skat.ui.nav.Route
import com.jackwallner.skat.ui.nav.SessionPurpose
import com.jackwallner.skat.ui.theme.CapsuleBar
import com.jackwallner.skat.ui.theme.DayPickerRow
import com.jackwallner.skat.ui.theme.SkatSwitch
import com.jackwallner.skat.ui.theme.TimePickerRow
import com.jackwallner.skat.ui.theme.Eyebrow
import com.jackwallner.skat.ui.theme.IconBadge
import com.jackwallner.skat.ui.theme.Skat
import com.jackwallner.skat.ui.theme.SkatScreen
import com.jackwallner.skat.ui.theme.SkatType
import com.jackwallner.skat.ui.theme.PrimaryCTA
import com.jackwallner.skat.ui.theme.Readable
import com.jackwallner.skat.ui.theme.navBarPadding
import com.jackwallner.skat.ui.theme.pressable
import com.jackwallner.skat.ui.theme.rounded
import com.jackwallner.skat.ui.theme.themedCard
import kotlin.math.roundToInt

private fun percent(fraction: Double) = "${(fraction * 100).roundToInt()}%"

/** One tap between Home and the first dealt hand. */
@Composable
fun EndlessPickerScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Skat.colors
    SkatScreen("Endlos üben", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    Modifier.fillMaxWidth().padding(top = 12.dp).background(colors.jade.copy(alpha = 0.10f), rounded(16.dp)).padding(14.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Icon(symbol("infinity"), null, tint = colors.jade, modifier = Modifier.size(20.dp))
                    Text(
                        "Jede Aufgabe wird erst erzeugt, wenn du sie siehst. Übe so lange du möchtest.",
                        style = SkatType.subheadline,
                        color = colors.inkSecondary,
                    )
                }
                PracticeSkill.entries.forEach { skill ->
                    val record = graph.records.records[skill.raw]
                    Row(
                        Modifier.fillMaxWidth().testTag("skill-${skill.raw}").pressable {
                            navigator.push(Route.Practice(PracticeMode.Endless(skill)))
                        }.themedCard().padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        IconBadge(skill.icon, colors.jade, size = 48.dp, iconSize = 24.dp, corner = 14.dp, alpha = 0.12f)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text(skill.title, style = SkatType.headline, color = colors.ink)
                            Text(skill.subtitle, style = SkatType.subheadline, color = colors.inkSecondary)
                            if (record != null && record.attempts > 0) {
                                Text("${percent(record.accuracy)} bei ${record.attempts} Antworten", style = SkatType.caption2, color = colors.inkTertiary)
                            }
                        }
                        Icon(symbol("chevron.right"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
    }
}

/**
 * Practice history: overall accuracy, a bar per room, and the weak spot worth
 * working on next. Free for everyone.
 */
@Composable
fun StatsScreen() {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Skat.colors
    val records = graph.records
    val progress = graph.progress
    val roomStats = records.roomStats()
    SkatScreen("Dein Fortschritt", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                if (records.totalAttempts == 0) {
                    Column(
                        Modifier.fillMaxWidth().padding(top = 12.dp).themedCard().padding(28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(symbol("chart.bar.fill"), null, tint = colors.jade.copy(alpha = 0.5f), modifier = Modifier.size(40.dp))
                        Text("Noch keine Übung", style = SkatType.headline, color = colors.ink)
                        Text(
                            "Beantworte ein paar Fragen, dann siehst du hier deine Genauigkeit pro Raum.",
                            style = SkatType.subheadline,
                            color = colors.inkSecondary,
                            textAlign = TextAlign.Center,
                        )
                    }
                } else {
                    Row(
                        Modifier.fillMaxWidth().padding(top = 12.dp).themedCard().padding(vertical = 18.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        StatMetric(percent(records.overallAccuracy), "Genauigkeit", colors.jade, Modifier.weight(1f))
                        Divider()
                        StatMetric("${records.totalAttempts}", "Antworten", colors.ink, Modifier.weight(1f))
                        Divider()
                        StatMetric("${records.bestChallengeScore}", "Zeitprüfung", colors.coral, Modifier.weight(1f))
                    }
                    val weakest = records.weakestRoom()
                    if (weakest != null && roomStats.size > 1) {
                        IconCard("target", colors.coral, "Übe als Nächstes: ${weakest.name}", "${percent(weakest.accuracy)} richtig bei ${weakest.attempts} Fragen, dein bisher schwächster Raum.")
                    }
                    AccuracyBreakdown(roomStats)
                }
                val sessions = progress.totalSessions
                IconCard("flame.fill", colors.coral, "${progress.streakCount} Tage am Stück", "$sessions Übungen abgeschlossen")
            }
        }
    }
}

@Composable
private fun Divider() {
    Box(Modifier.width(1.dp).height(34.dp).background(Skat.colors.rule))
}

@Composable
private fun StatMetric(value: String, caption: String, color: Color, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, style = SkatType.display(26.sp), color = color)
        Text(caption, style = SkatType.caption, color = Skat.colors.inkSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun IconCard(icon: String, tint: Color, title: String, body: String) {
    val colors = Skat.colors
    Row(
        Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBadge(icon, tint, alpha = 0.13f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(title, style = SkatType.headline, color = colors.ink)
            Text(body, style = SkatType.caption, color = colors.inkSecondary)
        }
    }
}

@Composable
private fun barColor(fraction: Double): Color {
    val colors = Skat.colors
    return when {
        fraction >= 0.8 -> colors.bamGreen
        fraction >= 0.6 -> colors.gold
        else -> colors.coral
    }
}

@Composable
private fun AccuracyBreakdown(stats: List<PracticeRecordStore.RoomStat>) {
    val colors = Skat.colors
    Column(Modifier.fillMaxWidth().themedCard().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Eyebrow("NACH RAUM")
        stats.forEach { stat ->
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row {
                    Text(stat.name, style = SkatType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink, modifier = Modifier.weight(1f))
                    Text(percent(stat.accuracy), style = SkatType.subheadline.copy(fontWeight = FontWeight.Bold), color = barColor(stat.accuracy))
                }
                CapsuleBar(stat.accuracy.toFloat(), barColor(stat.accuracy))
                Text("${stat.correct} von ${stat.attempts} richtig", style = SkatType.caption2, color = colors.inkTertiary)
            }
        }
    }
}

/** The weekly game-night reminder and the personalised prep session. */
@Composable
fun GameNightPrepScreen(requestNotifications: (onGranted: () -> Unit) -> Unit) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Skat.colors
    val settings = graph.settings
    val records = graph.records
    SkatScreen("Skatabend-Vorbereitung", onBack = { navigator.pop() }) {
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(16.dp).padding(navBarPadding()), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(
                    Modifier.fillMaxWidth().themedCard().padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    IconBadge("person.2.fill", colors.plum, size = 68.dp, iconSize = 30.dp)
                    Text("Vorbereitet an den Tisch", style = SkatType.display(28.sp), color = colors.ink)
                    Text(
                        "Lege deinen üblichen Skatabend fest. Die Erinnerung öffnet eine frische Runde aus deinen Fehlern, deinem schwächsten Raum und Material, das du noch nicht gesehen hast.",
                        style = SkatType.subheadline,
                        color = colors.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
                Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Eyebrow("WÖCHENTLICHE ERINNERUNG")
                            Text(
                                if (settings.gameNightReminderEnabled) "Vorbereitung ist geplant" else "Wähle deinen Skatabend",
                                style = SkatType.headline,
                                color = colors.ink,
                            )
                        }
                        SkatSwitch(settings.gameNightReminderEnabled, "Wöchentliche Erinnerung an den Skatabend") { on ->
                            if (on) requestNotifications { settings.updateGameNightReminderEnabled(true) }
                            else settings.updateGameNightReminderEnabled(false)
                        }
                    }
                    Box(Modifier.fillMaxWidth().height(1.dp).background(colors.rule))
                    DayPickerRow(settings.gameNightDay) { settings.updateGameNightDay(it) }
                    TimePickerRow("Erinnerung", settings.gameNightHour, settings.gameNightMinute) { hour, minute ->
                        settings.updateGameNightTime(hour, minute)
                    }
                    Text(
                        "Zu dieser Zeit öffnet die Mitteilung jeden ${settings.gameNightDay.displayName} direkt deine persönliche Übungsrunde.",
                        style = SkatType.caption,
                        color = colors.inkSecondary,
                    )
                }
                val weakest = records.weakestRoom()
                val due = records.dueCount
                val copy = when {
                    due > 0 && weakest != null -> "$due fällige${if (due == 1) "r Fehler" else " Fehler"} zuerst, danach Extra-Übung in ${weakest.name}."
                    due > 0 -> "$due fällige${if (due == 1) "r Fehler" else " Fehler"} zuerst, danach Material, das du noch nicht gesehen hast."
                    weakest != null -> "Extra-Übung in ${weakest.name}, danach eine ausgewogene Mischung aus den anderen Räumen."
                    else -> "Jetzt eine ausgewogene Mitglieder-Mischung. Je mehr Fragen du beantwortest, desto genauer trifft diese Runde deine echten Schwachstellen."
                }
                Row(Modifier.fillMaxWidth().themedCard(16.dp).padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    IconBadge("scope", colors.coral, size = 40.dp)
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text("Darauf zielt die Vorbereitung", style = SkatType.headline, color = colors.ink)
                        Text(copy, style = SkatType.subheadline, color = colors.inkSecondary)
                    }
                }
                PrimaryCTA("Fünf Minuten vorbereiten", Modifier.testTag("start-prep"), color = colors.plum) {
                    navigator.push(Route.Session(gameNightPrepItems(graph), SessionPurpose.GameNightPrep))
                }
                Spacer(Modifier.height(4.dp))
            }
        }
    }
}

fun gameNightPrepItems(graph: com.jackwallner.skat.AppGraph) = SessionBuilder.gameNightPrep(
    seen = graph.progress.seenItems,
    missed = graph.progress.missedItems,
    dueIDs = graph.records.reviewQueue(),
    weakestRoomID = graph.records.weakestRoom()?.id,
)
