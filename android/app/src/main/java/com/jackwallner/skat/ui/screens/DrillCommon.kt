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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import com.jackwallner.skat.AppGraph
import com.jackwallner.skat.model.Drill
import com.jackwallner.skat.ui.LocalAppActions
import com.jackwallner.skat.ui.LocalGraph
import com.jackwallner.skat.ui.components.ConfettiBurst
import com.jackwallner.skat.ui.components.symbol
import com.jackwallner.skat.ui.theme.Haptics
import com.jackwallner.skat.ui.theme.Skat
import com.jackwallner.skat.ui.theme.SkatType
import com.jackwallner.skat.ui.theme.PrimaryCTA
import com.jackwallner.skat.ui.theme.SoundPlayer
import com.jackwallner.skat.ui.theme.screenPadding
import com.jackwallner.skat.ui.theme.themedCard

/** One graded answer, feeding both the daily mix and the review schedule. */
fun AppGraph.recordAnswer(itemID: String, roomID: String, correct: Boolean, isReviewable: Boolean = true) {
    if (isReviewable) progress.recordItem(itemID, correct)
    records.record(itemID, roomID, correct, isReviewable)
}

fun celebrateCorrect() {
    Haptics.correctAnswer()
    SoundPlayer.play(SoundPlayer.Effect.SUCCESS)
}

fun consoleMiss() {
    Haptics.wrongAnswer()
    SoundPlayer.play(SoundPlayer.Effect.MISS)
}

/**
 * The end of every drill: score, streak, confetti. Recording happens once, on
 * first appearance, and a finished drill is the review funnel's positive moment.
 */
@Composable
fun DrillCompleteScreen(drill: Drill, score: Int?, total: Int, onDone: () -> Unit) {
    val graph = LocalGraph.current
    val actions = LocalAppActions.current
    val colors = Skat.colors
    var recorded by rememberSaveable { mutableStateOf(false) }
    var celebrate by rememberSaveable { mutableStateOf(false) }
    var confetti by rememberSaveable { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        celebrate = true
        confetti += 1
        if (recorded) return@LaunchedEffect
        recorded = true
        Haptics.success()
        SoundPlayer.play(SoundPlayer.Effect.COMPLETE)
        graph.progress.recordSession(drill.id)
        actions.positiveMoment()
    }
    val ring by animateFloatAsState(if (celebrate) 1f else 0.6f, spring(dampingRatio = 0.6f, stiffness = 300f), label = "ring")
    val fraction = if (score == null) 1.0 else score.toDouble() / maxOf(total, 1)
    val headline = when {
        score == null -> "Stapel geschafft!"
        fraction >= 1 -> "Perfekte Runde!"
        fraction >= 0.7 -> "Sehr gut!"
        else -> "Gute Übung!"
    }
    val subheadline = if (score == null) "Alle $total Karten sind eingeordnet. Mit jeder Runde sitzt es ein wenig besser."
    else "Jede Entscheidung, die du hier übst, liest du am Tisch schneller."
    Box(Modifier.fillMaxSize().background(colors.background)) {
        Column(
            Modifier.fillMaxSize().screenPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Spacer(Modifier.weight(1f))
            Box(contentAlignment = Alignment.Center) {
                Box(Modifier.size(132.dp).scale(ring).background(colors.jade.copy(alpha = 0.12f), CircleShape))
                if (score != null) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("$score/$total", style = SkatType.display(34.sp), color = colors.jade, modifier = Modifier.testTag("drill-score"))
                        Text("richtig", style = SkatType.caption.copy(fontWeight = FontWeight.SemiBold), color = colors.inkSecondary)
                    }
                } else {
                    Icon(symbol("checkmark.seal.fill"), null, tint = colors.jade, modifier = Modifier.size(58.dp))
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(headline, style = SkatType.display(30.sp), color = colors.ink, textAlign = TextAlign.Center)
                Text(subheadline, style = SkatType.body, color = colors.inkSecondary, textAlign = TextAlign.Center)
            }
            Row(
                Modifier.themedCard(22.dp).padding(horizontal = 18.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Icon(symbol("flame.fill"), null, tint = colors.coral, modifier = Modifier.size(18.dp))
                Text("${graph.progress.streakCount} Tage am Stück", style = SkatType.headline, color = colors.ink)
            }
            Spacer(Modifier.weight(1f))
            PrimaryCTA("Fertig", Modifier.testTag("drill-done"), onClick = onDone)
        }
        ConfettiBurst(confetti, origin = Offset(0.5f, 0.3f), particleCount = 44)
    }
}

/** The counter line a drill shows under the question until it is answered. */
@Composable
fun FooterCounter(text: String) {
    Box(Modifier.fillMaxWidth().height(54.dp), contentAlignment = Alignment.Center) {
        Text(text, style = SkatType.caption, color = Skat.colors.inkTertiary)
    }
}

/** A body screen for a run with nothing in it: never scored as a finished round. */
@Composable
fun EmptyRunScreen(icon: String, title: String, body: String, onBack: () -> Unit) {
    val colors = Skat.colors
    Column(
        Modifier.fillMaxSize().background(colors.background).screenPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Spacer(Modifier.weight(1f))
        Icon(symbol(icon), null, tint = colors.jade, modifier = Modifier.size(48.dp))
        Text(title, style = SkatType.display(28.sp), color = colors.ink, textAlign = TextAlign.Center)
        Text(body, style = SkatType.subheadline, color = colors.inkSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.weight(1f))
        PrimaryCTA("Zurück", onClick = onBack)
    }
}

