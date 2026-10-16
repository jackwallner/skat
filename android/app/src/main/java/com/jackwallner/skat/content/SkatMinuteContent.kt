package com.jackwallner.skat.content

import com.jackwallner.skat.model.ChoiceShuffle
import com.jackwallner.skat.model.DiscardScenario
import com.jackwallner.skat.model.Drill
import com.jackwallner.skat.model.DrillKind
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.StableSeededGenerator
import java.time.LocalDate
import java.util.Locale

enum class SkatMinuteCategory(val raw: String, val title: String, val icon: String) {
    HAND_READING("handReading", "Blattlesen", "rectangle.on.rectangle.angled"),
    DRUECKEN("druecken", "Drücken", "arrow.down.circle.fill"),
    STICHSPIEL("stichspiel", "Stichspiel", "hand.point.up.left.fill"),
}

data class SkatMinuteQuestion(val category: SkatMinuteCategory, val item: QuickItem)

data class SkatMinuteChallenge(
    val day: LocalDate,
    val dayKey: String,
    val shortDate: String,
    val questions: List<SkatMinuteQuestion>,
) {
    val items: List<QuickItem> get() = questions.map { it.item }
}

/**
 * One shared five-question set per calendar date, identical to the iOS set for
 * the same date: two generated hand reads, one Drücken decision and two
 * Stichspiel questions, all picked with the same seeds as iOS.
 */
object SkatMinuteContent {
    const val QUESTION_COUNT = 5

    val drill = Drill("skat-minute", "Skat-Minute", "Die tägliche Runde mit fünf Fragen", DrillKind.Quiz(emptyList()), isPlus = true)

    fun key(day: LocalDate): String = String.format(Locale.US, "%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)

    fun challenge(day: LocalDate = LocalDate.now()): SkatMinuteChallenge {
        val dayKey = key(day)
        val generated = generatedQuestions(dayKey)
        val middle = listOfNotNull(drueckenQuestion(dayKey))
        val last = roomQuestions(dayKey, "pegging-room", SkatMinuteCategory.STICHSPIEL, 2)
        // Interleaved so the run does not read as three separate quizzes.
        val questions = buildList {
            generated.getOrNull(0)?.let(::add)
            addAll(middle)
            last.getOrNull(0)?.let(::add)
            generated.getOrNull(1)?.let(::add)
            last.getOrNull(1)?.let(::add)
        }
        val shortDate = String.format(Locale.US, "%02d/%02d", day.monthValue, day.dayOfMonth)
        return SkatMinuteChallenge(day, dayKey, shortDate, questions)
    }

    private fun generatedQuestions(dayKey: String): List<SkatMinuteQuestion> =
        HandGenerator.batch(2, "skat-minute-$dayKey-hands").mapIndexed { index, hand ->
            val item = QuickItem(
                id = PracticeSkill.HAND_READING.itemPrefix + "minute-$dayKey-$index",
                prompt = "Welches Spiel passt zu diesem Blatt?",
                tiles = hand.tiles,
                choices = hand.choices.map { it.displayName },
                answerIndex = hand.choices.indexOf(hand.answer).coerceAtLeast(0),
                explanation = hand.explanation,
                sourceLabel = "Skat-Minute: Blattlesen",
                roomID = PracticeSkill.HAND_READING.roomID,
                trackingID = PracticeSkill.HAND_READING.raw,
                isReviewable = false,
            )
            SkatMinuteQuestion(SkatMinuteCategory.HAND_READING, SessionBuilder.prepared(item))
        }

    /** Built straight from the authored scenarios: the quick-session pool leaves discards out. */
    private fun drueckenQuestion(dayKey: String): SkatMinuteQuestion? {
        val scenarios = DrillLibrary.rooms.flatMap { room ->
            room.drills.flatMap { (it.kind as? DrillKind.Discard)?.scenarios ?: emptyList() }
        }
        if (scenarios.isEmpty()) return null
        val generator = StableSeededGenerator("skat-minute-$dayKey-druecken")
        val scenario = scenarios[(generator.next() % scenarios.size.toULong()).toInt()]
        val answer = label(scenario.recommendedDiscard)
        val distractors = distractorLabels(scenario, dayKey, answer)
        if (distractors.size < 2) return null
        val item = QuickItem(
            id = "skat-minute-druecken-$dayKey",
            prompt = "${scenario.situation} Welche beiden Karten drückst du?",
            tiles = scenario.deal,
            choices = listOf(answer) + distractors,
            answerIndex = 0,
            explanation = scenario.reasoning,
            sourceLabel = "Skat-Minute: Drücken",
            roomID = "discard-room",
            trackingID = "skat-minute-druecken",
            isReviewable = false,
        )
        return SkatMinuteQuestion(SkatMinuteCategory.DRUECKEN, SessionBuilder.prepared(item))
    }

    /** Every other pair from the same deal, so a wrong answer is a real alternative. */
    private fun distractorLabels(scenario: DiscardScenario, dayKey: String, answer: String): List<String> {
        val labels = mutableSetOf<String>()
        for (first in 0 until maxOf(0, scenario.deal.size - 1)) {
            for (second in first + 1 until scenario.deal.size) {
                labels += label(listOf(scenario.deal[first], scenario.deal[second]))
            }
        }
        labels -= answer
        val sorted = labels.sorted()
        val order = ChoiceShuffle.permutation(sorted.size, "skat-minute-$dayKey-druecken-choices")
        return order.take(3).map { sorted[it] }
    }

    private fun label(cards: List<PlayingCard>): String = cards.joinToString(", ") { it.spokenName }

    /** Authored questions from one room, picked by a permutation of the day key. */
    private fun roomQuestions(dayKey: String, roomID: String, category: SkatMinuteCategory, count: Int): List<SkatMinuteQuestion> {
        val pool = SessionBuilder.choiceItems(roomID, includePro = true)
        if (pool.isEmpty()) return emptyList()
        val indices = ChoiceShuffle.permutation(pool.size, "skat-minute-$dayKey-$roomID")
        return indices.take(count).map { SkatMinuteQuestion(category, SessionBuilder.prepared(pool[it])) }
    }
}
