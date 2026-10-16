package com.jackwallner.skat.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.skat.content.DrillLibrary
import com.jackwallner.skat.model.DiscardScenario
import com.jackwallner.skat.model.Drill
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.racked
import com.jackwallner.skat.ui.LocalGraph
import com.jackwallner.skat.ui.components.DrillProgress
import com.jackwallner.skat.ui.components.DrillStage
import com.jackwallner.skat.ui.components.CardHandView
import com.jackwallner.skat.ui.components.PlayingCardView
import com.jackwallner.skat.ui.components.shine
import com.jackwallner.skat.ui.components.symbol
import com.jackwallner.skat.ui.nav.LocalNavigator
import com.jackwallner.skat.ui.theme.CenteringScroll
import com.jackwallner.skat.ui.theme.Skat
import com.jackwallner.skat.ui.theme.SkatScreen
import com.jackwallner.skat.ui.theme.SkatType
import com.jackwallner.skat.ui.theme.PrimaryCTA
import com.jackwallner.skat.ui.theme.Readable
import com.jackwallner.skat.ui.theme.rounded
import com.jackwallner.skat.ui.theme.screenPadding
import com.jackwallner.skat.ui.theme.themedCard
import kotlinx.coroutines.delay

/** Grade a discard by card multiset, so equivalent duplicates count as matches. */
fun matchCount(selected: Collection<Int>, rack: List<PlayingCard>, recommended: List<PlayingCard>): Int {
    val pool = recommended.toMutableList()
    return selected.count { index -> pool.indexOf(rack[index]).takeIf { it >= 0 }?.let { pool.removeAt(it) } != null }
}

@Composable
fun DiscardDrillScreen(drill: Drill, scenarios: List<DiscardScenario>) {
    val graph = LocalGraph.current
    val navigator = LocalNavigator.current
    val colors = Skat.colors
    var index by rememberSaveable { mutableIntStateOf(0) }
    var selected by rememberSaveable { mutableStateOf(listOf<Int>()) }
    var submitted by rememberSaveable { mutableStateOf(false) }
    var score by rememberSaveable { mutableIntStateOf(0) }
    var finished by rememberSaveable { mutableStateOf(false) }
    var confetti by remember { mutableIntStateOf(0) }
    var shineTrigger by remember { mutableIntStateOf(0) }

    if (finished) {
        DrillCompleteScreen(drill, score, scenarios.size * 2) { navigator.pop() }
        return
    }
    val scenario = scenarios[index]
    val rack = remember(scenario.id) { scenario.deal.racked }
    val matches = matchCount(selected, rack, scenario.recommendedDiscard)

    LaunchedEffect(submitted, index) {
        if (submitted && matches == 2) {
            delay(350)
            shineTrigger += 1
        }
    }

    SkatScreen(drill.title, onBack = { navigator.pop() }) {
        DrillStage(confetti) {
            Readable(Modifier.fillMaxSize()) {
                Column(Modifier.fillMaxSize().screenPadding(), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    DrillProgress(index, scenarios.size)
                    CenteringScroll(Modifier.weight(1f)) {
                        Column(
                            Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(18.dp),
                        ) {
                            Text(
                                scenario.situation,
                                style = SkatType.display(20.sp, FontWeight.SemiBold),
                                color = colors.ink,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(top = 8.dp),
                            )
                            CardHandView(rack, Modifier.padding(vertical = 6.dp), cardWidth = 48.dp, highlighted = selected.toSet()) { tapped ->
                                if (submitted) return@CardHandView
                                selected = when {
                                    tapped in selected -> selected - tapped
                                    selected.size >= 2 -> selected
                                    else -> selected + tapped
                                }
                            }
                            AnimatedVisibility(submitted, enter = fadeIn() + scaleIn(initialScale = 0.94f)) {
                                CoachCard(scenario, matches, shineTrigger)
                            }
                            if (!submitted) {
                                Text("${selected.size} von 2 ausgewählt", style = SkatType.subheadline, color = colors.inkSecondary)
                            }
                        }
                    }
                    if (submitted) {
                        PrimaryCTA(if (index + 1 < scenarios.size) "Nächste Entscheidung" else "Fertig", Modifier.testTag("next")) {
                            if (index + 1 < scenarios.size) {
                                selected = emptyList()
                                submitted = false
                                index += 1
                            } else {
                                finished = true
                            }
                        }
                    } else {
                        PrimaryCTA("Diese 2 drücken", Modifier.testTag("discard"), enabled = selected.size == 2) {
                            submitted = true
                            score += matches
                            val correct = matches == 2
                            graph.recordAnswer(scenario.id, DrillLibrary.roomID(drill.id), correct)
                            if (correct) {
                                confetti += 1
                                celebrateCorrect()
                            } else {
                                consoleMiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CoachCard(scenario: DiscardScenario, matches: Int, shineTrigger: Int) {
    val colors = Skat.colors
    val headline = when (matches) {
        2 -> "Perfekt gedrückt, 2 von 2"
        1 -> "Fast, 1 von 2 getroffen"
        else -> "Die Lehrentscheidung war anders"
    }
    Column(
        Modifier
            .fillMaxWidth()
            .shadow(if (matches == 2) 16.dp else 0.dp, rounded(16.dp), ambientColor = colors.gold, spotColor = colors.gold)
            .themedCard(16.dp)
            .shine(shineTrigger, 16.dp)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(symbol(if (matches == 2) "star.fill" else "graduationcap.fill"), null, tint = colors.gold, modifier = Modifier.size(20.dp))
            Text(headline, style = SkatType.headline, color = colors.ink, modifier = Modifier.testTag("coach-headline"))
        }
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("Lehrentscheidung für den Skat:", style = SkatType.subheadline.copy(fontWeight = FontWeight.SemiBold), color = colors.ink)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                scenario.recommendedDiscard.forEach { PlayingCardView(it, 42.dp) }
            }
        }
        Text(scenario.reasoning, style = SkatType.subheadline, color = colors.ink)
        Row(
            Modifier.fillMaxWidth().background(colors.gold.copy(alpha = 0.12f), rounded(10.dp)).padding(10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(symbol("lightbulb.fill"), null, tint = colors.gold, modifier = Modifier.size(18.dp))
            Text(scenario.tip, style = SkatType.footnote.copy(fontWeight = FontWeight.Medium), color = colors.ink)
        }
    }
}
