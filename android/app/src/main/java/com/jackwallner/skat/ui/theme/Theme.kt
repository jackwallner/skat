package com.jackwallner.skat.ui.theme

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.skat.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private fun rgb(r: Double, g: Double, b: Double) = Color(r.toFloat(), g.toFloat(), b.toFloat())

/**
 * The warm-modern palette from iOS `Theme.swift`, value for value: cream
 * surfaces, jade primary, coral energy, gold for the membership, plum for the
 * Discard room. Every ink level clears WCAG AA on both backgrounds.
 */
@Immutable
data class SkatColors(
    val isDark: Boolean,
    val jade: Color,
    val coral: Color,
    val gold: Color,
    val plum: Color,
    val background: Color,
    val card: Color,
    val well: Color,
    val rule: Color,
    val ink: Color,
    val inkSecondary: Color,
    val inkTertiary: Color,
    val cardEdge: Color,
    val cardRed: Color,
) {
    // Compatibility aliases the iOS Theme keeps for the shared drill effects.
    val tileIvory get() = card
    val tileEdge get() = cardEdge
    val crakRed get() = cardRed
    val bamGreen get() = jade
    val dotBlue get() = coral
    val jokerPurple get() = plum
    val flowerPink get() = coral

    companion object {
        val light = SkatColors(
            isDark = false,
            jade = rgb(0.09, 0.42, 0.36),
            coral = rgb(0.86, 0.42, 0.31),
            gold = rgb(0.76, 0.57, 0.18),
            plum = rgb(0.48, 0.28, 0.52),
            background = rgb(0.97, 0.945, 0.90),
            card = rgb(1.0, 0.99, 0.965),
            well = rgb(0.945, 0.915, 0.86),
            rule = rgb(0.86, 0.82, 0.75),
            ink = rgb(0.16, 0.14, 0.12),
            inkSecondary = rgb(0.38, 0.35, 0.31),
            inkTertiary = rgb(0.46, 0.42, 0.38),
            cardEdge = rgb(0.76, 0.70, 0.61),
            cardRed = rgb(0.72, 0.16, 0.15),
        )
        val dark = SkatColors(
            isDark = true,
            jade = rgb(0.36, 0.71, 0.62),
            coral = rgb(0.94, 0.56, 0.45),
            gold = rgb(0.88, 0.72, 0.38),
            plum = rgb(0.72, 0.53, 0.76),
            background = rgb(0.11, 0.10, 0.09),
            card = rgb(0.17, 0.155, 0.14),
            well = rgb(0.14, 0.13, 0.115),
            rule = rgb(0.28, 0.26, 0.235),
            ink = rgb(0.94, 0.92, 0.88),
            inkSecondary = rgb(0.72, 0.69, 0.64),
            inkTertiary = rgb(0.62, 0.59, 0.55),
            cardEdge = rgb(0.53, 0.48, 0.42),
            cardRed = rgb(0.96, 0.49, 0.43),
        )
    }
}

val LocalSkatColors = staticCompositionLocalOf { SkatColors.light }

object Skat {
    val colors: SkatColors
        @Composable @ReadOnlyComposable get() = LocalSkatColors.current
}

@Composable
fun SkatTheme(dark: Boolean, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalSkatColors provides if (dark) SkatColors.dark else SkatColors.light, content = content)
}

/** The iOS text styles at their default Dynamic Type sizes. */
object SkatType {
    private val system = FontFamily.Default

    /** Serif display for titles: the "skat club" voice. */
    fun display(size: TextUnit, weight: FontWeight = FontWeight.Bold) =
        TextStyle(fontFamily = FontFamily.Serif, fontWeight = weight, fontSize = size, lineHeight = size * 1.18f)

    val title3 = TextStyle(fontFamily = system, fontSize = 20.sp, lineHeight = 25.sp)
    val headline = TextStyle(fontFamily = system, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, lineHeight = 22.sp)
    val body = TextStyle(fontFamily = system, fontSize = 17.sp, lineHeight = 23.sp)
    val subheadline = TextStyle(fontFamily = system, fontSize = 15.sp, lineHeight = 20.sp)
    val footnote = TextStyle(fontFamily = system, fontSize = 13.sp, lineHeight = 18.sp)
    val caption = TextStyle(fontFamily = system, fontSize = 12.sp, lineHeight = 16.sp)
    val caption2 = TextStyle(fontFamily = system, fontSize = 11.sp, lineHeight = 13.sp)

    /** The small uppercase eyebrow used for section headings. */
    val eyebrow = caption.copy(fontWeight = FontWeight.ExtraBold, letterSpacing = 1.4.sp)
}

object SkatGeo {
    val cardCorner = 20.dp
    val deckCorner = 26.dp
    val ctaHeight = 56.dp
    val ctaCorner = 18.dp
    val readableWidth = 760.dp
}

/**
 * Grading haptics have to feel like opposites in the hand: right is a crisp
 * tick into a confirm, wrong is a dull double thud.
 */
object Haptics {
    @Volatile var enabled: Boolean = true
    @Volatile private var view: View? = null
    private val scope = CoroutineScope(Dispatchers.Main)

    fun attach(view: View?) {
        this.view = view
    }

    fun light() = perform(HapticFeedbackConstants.CLOCK_TICK)
    fun soft() = perform(HapticFeedbackConstants.CLOCK_TICK)
    fun rigid() = perform(HapticFeedbackConstants.VIRTUAL_KEY)
    fun success() = perform(if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY)
    fun error() = perform(if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS)

    fun correctAnswer() {
        light()
        scope.launch {
            delay(70)
            success()
        }
    }

    fun wrongAnswer() {
        perform(HapticFeedbackConstants.LONG_PRESS)
        scope.launch {
            delay(110)
            perform(HapticFeedbackConstants.CLOCK_TICK)
        }
    }

    private fun perform(constant: Int) {
        if (!enabled) return
        view?.performHapticFeedback(constant)
    }
}

/** The app's three short UI sounds, respecting the Settings toggle. */
object SoundPlayer {
    enum class Effect(val resource: Int) {
        SUCCESS(R.raw.sound_success),
        MISS(R.raw.sound_miss),
        COMPLETE(R.raw.sound_complete),
    }

    @Volatile var enabled: Boolean = true
    private var pool: SoundPool? = null
    private val ids = mutableMapOf<Effect, Int>()

    fun load(context: Context) {
        if (pool != null) return
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val created = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(attributes).build()
        Effect.entries.forEach { ids[it] = created.load(context, it.resource, 1) }
        pool = created
    }

    fun play(effect: Effect) {
        if (!enabled) return
        val id = ids[effect] ?: return
        pool?.play(id, 0.8f, 0.8f, 1, 0, 1f)
    }
}
