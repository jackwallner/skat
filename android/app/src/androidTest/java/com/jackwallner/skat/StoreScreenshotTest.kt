package com.jackwallner.skat

import android.content.Intent
import android.graphics.Bitmap
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Raw captures for the Play listing: the same six screens as the App Store set
 * (scripts/screenshot_raw/), named as scripts/play_screenshot_compositor.py
 * expects. Excluded from `connectedDebugAndroidTest` (`notClass` in
 * build.gradle.kts); run it with
 * `am instrument -e class com.jackwallner.skat.StoreScreenshotTest`.
 * Files land in the app's external files dir under `screens/`.
 */
@RunWith(AndroidJUnit4::class)
class StoreScreenshotTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    @After
    fun tearDown() {
        scenario?.close()
    }

    @Test
    fun capture01QuickSession() {
        launch()
        tag("get-started")
        compose.waitUntil(30_000) {
            listOf("choice-0", "card-choice-0", "hand-card-0").any {
                compose.onAllNodes(hasTestTag(it)).fetchSemanticsNodes().isNotEmpty()
            } || compose.onAllNodes(hasText("Tippen zum Aufdecken")).fetchSemanticsNodes().isNotEmpty()
        }
        capture("01-quicksession")
    }

    @Test
    fun capture02HandMatch() {
        openDrill("scoring-room", "hand-match")
        waitForTag("choice-0")
        capture("02-handmatch")
    }

    @Test
    fun capture03Discard() {
        openDrill("discard-room", "discard-two")
        waitForTag("hand-card-0")
        capture("03-keepdiscard")
    }

    @Test
    fun capture04Stichspiel() {
        openDrill("pegging-room", "pegging-judgment")
        waitForText("Entscheide dich")
        capture("04-stichspiel")
    }

    @Test
    fun capture05Home() {
        launch(seed = true)
        waitForText("Dein Platz am Tisch.")
        capture("05-home")
    }

    @Test
    fun capture06CardRoom() {
        launch()
        tag("room-card-room")
        waitForTag("drill-meet-cards")
        capture("06-cardroom")
    }

    private fun launch(seed: Boolean = false) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
            .putExtra("resetAll", true)
            .putExtra("uiTest", true)
            .putExtra("onboarded", true)
            .putExtra("seedProgress", seed)
            .putExtra("appearance", "light")
        scenario = ActivityScenario.launch(intent)
    }

    private fun openDrill(room: String, drill: String) {
        launch()
        tag("room-$room")
        tag("drill-$drill")
    }

    private fun waitForTag(tag: String) {
        compose.waitUntil(30_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
    }

    private fun waitForText(text: String) {
        compose.waitUntil(30_000) { compose.onAllNodes(hasText(text, substring = true)).fetchSemanticsNodes().isNotEmpty() }
    }

    private fun tag(tag: String) {
        waitForTag(tag)
        runCatching { compose.onNodeWithTag(tag).performScrollTo() }
        compose.onNodeWithTag(tag).performClick()
        compose.waitForIdle()
    }

    private fun capture(name: String) {
        compose.waitForIdle()
        Thread.sleep(1_500)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val bitmap: Bitmap = instrumentation.uiAutomation.takeScreenshot() ?: error("Screenshot failed for $name")
        val dir = File(instrumentation.targetContext.getExternalFilesDir(null), "screens").apply { mkdirs() }
        File(dir, "$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }
}
