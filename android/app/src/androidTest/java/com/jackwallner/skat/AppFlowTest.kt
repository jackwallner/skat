package com.jackwallner.skat

import android.content.Intent
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The first-run path, the free drills, and the paid boundary, on a real device. */
@RunWith(AndroidJUnit4::class)
class AppFlowTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    private fun launch(onboarded: Boolean, forcePro: Boolean = false, skill: String? = null) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
            .putExtra("resetAll", true)
            .putExtra("uiTest", true)
            .putExtra("onboarded", onboarded)
            .putExtra("forcePro", forcePro)
            .putExtra("appearance", "light")
        skill?.let { intent.putExtra("skillLevel", it) }
        scenario = ActivityScenario.launch(intent)
    }

    @After
    fun tearDown() {
        scenario?.close()
    }

    private fun waitFor(text: String, timeout: Long = 15_000) {
        compose.waitUntil(timeout) {
            compose.onAllNodes(hasText(text, substring = true) or hasContentDescription(text) or hasTestTag(text))
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Waits until exactly one node carries [tag] (transitions briefly show two), then taps it. */
    private fun tag(tag: String) {
        compose.waitUntil(15_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
        runCatching { compose.onNodeWithTag(tag).performScrollTo() }
        compose.onNodeWithTag(tag).performClick()
        compose.waitForIdle()
    }

    @Test
    fun onboardingSoftExitLandsOnHomeThroughTheTour() {
        launch(onboarded = false)
        waitFor("Zwischen den Runden sicherer werden")
        repeat(3) { tag("onboarding-primary") }
        tag("skill-played")
        tag("onboarding-primary")
        waitFor("Loslegen") // the trial page; its title depends on Play eligibility
        tag("soft-exit")
        waitFor("Vier Räume, vier Fähigkeiten")
        tag("tour-skip")
        waitFor("Dein Platz am Tisch.")
    }

    /** Answers the first choice until the drill reports its score. */
    private fun answerUntilScored(limit: Int = 40) {
        repeat(limit) {
            if (compose.onAllNodes(hasTestTag("drill-score")).fetchSemanticsNodes().isNotEmpty()) return
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("drill-score")
    }

    @Test
    fun freeQuizGradesAndFinishes() {
        launch(onboarded = true)
        tag("room-card-room")
        tag("drill-card-quiz")
        answerUntilScored()
        tag("drill-done")
        waitFor("Karten & Reizen")
    }

    @Test
    fun discardDrillTakesTwoCardsAndCoaches() {
        launch(onboarded = true)
        tag("room-discard-room")
        tag("drill-discard-two")
        tag("hand-card-0")
        tag("hand-card-1")
        tag("discard")
        waitFor("coach-headline")
        waitFor("Lehrentscheidung für den Skat:")
    }

    @Test
    fun lockedModesOpenThePaywallForFreePlayers() {
        launch(onboarded = true)
        tag("tile-endless")
        waitFor("Skat+ freischalten")
        waitFor("Wiederherstellen")
        waitFor("Nutzungsbedingungen")
        waitFor("Datenschutz")
    }

    @Test
    fun membersReachEndlessPractice() {
        launch(onboarded = true, forcePro = true)
        tag("tile-endless")
        tag("skill-handReading")
        waitFor("ENDLOS ÜBEN")
        tag("choice-0")
        waitFor("explanation")
    }

    @Test
    fun membersRunTheSkatMinute() {
        launch(onboarded = true, forcePro = true)
        tag("tile-minute")
        tag("start-minute")
        repeat(5) {
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("minute-score")
        waitFor("NACH FÄHIGKEIT")
    }
}
