package com.jackwallner.skat

import com.jackwallner.skat.content.SkatMinuteCategory
import com.jackwallner.skat.content.SkatMinuteContent
import com.jackwallner.skat.content.DrillLibrary
import com.jackwallner.skat.content.EndlessPractice
import com.jackwallner.skat.content.HandGenerator
import com.jackwallner.skat.content.PracticeSkill
import com.jackwallner.skat.content.QuickItem
import com.jackwallner.skat.content.SessionBuilder
import com.jackwallner.skat.model.ChoiceShuffle
import com.jackwallner.skat.model.HandCategory
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.PlayingCard.Companion.c
import com.jackwallner.skat.model.PlayingCard.Companion.d
import com.jackwallner.skat.model.PlayingCard.Companion.h
import com.jackwallner.skat.model.PlayingCard.Companion.s
import com.jackwallner.skat.model.StableSeededGenerator
import com.jackwallner.skat.model.Suit
import com.jackwallner.skat.model.nextBool
import java.time.LocalDate
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Holds the Kotlin generators to the iOS output, plus ports of iOS
 * `HandGeneratorTests` and `SkatMinuteContentTests`. The shared daily
 * challenge has to deal the same cards on both platforms.
 */
class GeneratorParityTest {
    private val parity = ParityFixtures.json

    private fun assertItem(label: String, expected: JSONObject, actual: QuickItem) {
        assertEquals(label, expected.getString("id"), actual.id)
        assertEquals(label, expected.getString("prompt"), actual.prompt)
        assertEquals(label, expected.getJSONArray("tiles").strings(), codes(actual.tiles))
        assertEquals(label, expected.getJSONArray("choices").strings(), actual.choices)
        assertEquals(label, expected.getInt("answerIndex"), actual.answerIndex)
        assertEquals(label, expected.getString("explanation"), actual.explanation)
        assertEquals(label, expected.getString("sourceLabel"), actual.sourceLabel)
        assertEquals(label, expected.getString("roomID"), actual.roomID)
        assertEquals(label, expected.getString("trackingID"), actual.trackingID)
        assertEquals(label, expected.getBoolean("isReviewable"), actual.isReviewable)
    }

    @Test
    fun seededStreamMatchesSwift() {
        val streams = parity.getJSONObject("streams")
        for (seed in streams.keys()) {
            val generator = StableSeededGenerator(seed)
            assertEquals("seed '$seed'", streams.getJSONArray(seed).strings(), (0 until 8).map { generator.next().toString() })
        }
    }

    @Test
    fun permutationsMatchSwift() {
        val permutations = parity.getJSONObject("permutations")
        for (key in permutations.keys()) {
            val (seed, count) = key.split("|")
            assertEquals(key, permutations.getJSONArray(key).ints(), ChoiceShuffle.permutation(count.toInt(), seed))
        }
    }

    @Test
    fun handBatchesMatchSwift() {
        val hands = parity.getJSONObject("hands")
        for (seed in hands.keys()) {
            val expected = hands.getJSONArray(seed).objects()
            val actual = HandGenerator.batch(7, seed)
            assertEquals(seed, expected.size, actual.size)
            expected.zip(actual).forEachIndexed { index, (json, hand) ->
                val label = "$seed #$index"
                assertEquals(label, json.getJSONArray("tiles").strings(), codes(hand.tiles))
                assertEquals(label, json.getString("answer"), hand.answer.raw)
                assertEquals(label, json.getJSONArray("choices").strings(), hand.choices.map { it.raw })
                assertEquals(label, json.getString("explanation"), hand.explanation)
            }
        }
    }

    @Test
    fun skatMinuteMatchesSwift() {
        val minutes = parity.getJSONObject("minutes")
        for (day in minutes.keys()) {
            val expected = minutes.getJSONObject(day)
            val challenge = SkatMinuteContent.challenge(LocalDate.parse(day))
            assertEquals(day, expected.getString("shortDate"), challenge.shortDate)
            val questions = expected.getJSONArray("questions").objects()
            assertEquals(day, questions.size, challenge.questions.size)
            questions.zip(challenge.questions).forEachIndexed { index, (json, question) ->
                assertEquals("$day #$index", json.getString("category"), question.category.raw)
                assertItem("$day #$index", json.getJSONObject("item"), question.item)
            }
        }
    }

    @Test
    fun preparedChoicePoolMatchesSwift() {
        val expected = parity.getJSONArray("memberPool").objects()
        val actual = DrillLibrary.rooms.flatMap { SessionBuilder.choiceItems(it.id, includePro = true) }.map(SessionBuilder::prepared)
        assertEquals(expected.size, actual.size)
        expected.zip(actual).forEach { (json, item) -> assertItem(item.id, json, item) }
    }

    @Test
    fun boolDrawsMatchSwift() {
        val bools = parity.getJSONObject("bools")
        for (seed in bools.keys()) {
            val generator = StableSeededGenerator(seed)
            val expected = bools.getJSONArray(seed).let { array -> (0 until array.length()).map { array.getBoolean(it) } }
            assertEquals(seed, expected, (0 until 16).map { generator.nextBool() })
        }
    }

    @Test
    fun cardFactsMatchSwift() {
        val facts = parity.getJSONArray("cardFacts").objects()
        assertEquals(32, facts.size)
        assertEquals(facts.map { it.getString("code") }, codes(PlayingCard.skatDeck))
        for ((json, card) in facts.zip(PlayingCard.skatDeck)) {
            assertEquals(json.getString("short"), card.shortLabel)
            assertEquals(json.getString("spoken"), card.spokenName)
            assertEquals(json.getInt("value"), card.skatValue)
            assertEquals(json.getInt("sortKey"), card.sortKey)
        }
        assertEquals(120, PlayingCard.skatDeck.sumOf { it.skatValue })
    }

    @Test
    fun classifierMatchesSwiftOnSeededLayouts() {
        val rows = parity.getJSONArray("classifications").objects()
        assertEquals(400, rows.size)
        for (row in rows) {
            val cards = row.getJSONArray("cards").cards()
            val fits = HandGenerator.generatableCategories.filter { HandGenerator.fits(cards, it) }.map { it.raw }
            assertEquals(cards.toString(), row.getJSONArray("fits").strings(), fits)
            assertEquals(cards.toString(), if (row.has("category")) row.getString("category") else null, HandGenerator.category(cards)?.raw)
        }
    }

    // MARK: - iOS HandGeneratorTests

    @Test
    fun readsEachPattern() {
        assertEquals(HandCategory.GRAND, HandGenerator.category(listOf(c(11), s(11), h(11), d(11), c(14))))
        val trumpf = listOf(c(11), s(11), h(7), h(10), h(14))
        assertEquals(HandCategory.TRUMPF, HandGenerator.category(trumpf))
        assertFalse(HandGenerator.fits(trumpf, HandCategory.GRAND))
        assertEquals(HandCategory.FARBE, HandGenerator.category(listOf(c(7), c(8), c(9), c(10), c(14))))
        assertEquals(HandCategory.NULLSPIEL, HandGenerator.category(listOf(c(7), d(8), h(9), s(10), c(8))))
        assertEquals(HandCategory.STICH, HandGenerator.category(listOf(c(14), d(14), h(13), s(12), c(10))))
    }

    @Test
    fun generatedHandsAreLegalAndUnambiguous() {
        for (target in HandGenerator.generatableCategories) {
            repeat(20) {
                val hand = HandGenerator.hand(target)
                assertNotNull("Could not deal ${target.raw}", hand)
                hand!!
                assertEquals(5, hand.tiles.size)
                assertEquals(5, hand.tiles.toSet().size)
                assertEquals(target, HandGenerator.category(hand.tiles))
                assertTrue(target in hand.choices)
                assertTrue(hand.choices.size >= 3)
                assertEquals(hand.choices.size, hand.choices.toSet().size)
                for (choice in hand.choices.filter { it != target }) assertFalse(HandGenerator.fits(hand.tiles, choice))
                assertTrue(hand.explanation.isNotEmpty() && "\u2014" !in hand.explanation)
            }
        }
    }

    @Test
    fun everyGeneratedCategoryUsesOnlyItsSuppliedSeed() {
        for (category in HandGenerator.generatableCategories) {
            for (seed in 0 until 50) {
                val first = StableSeededGenerator("expert-release-$seed")
                val second = StableSeededGenerator("expert-release-$seed")
                val a = HandGenerator.hand(category, source = first)!!
                val b = HandGenerator.hand(category, source = second)!!
                assertEquals(a.tiles, b.tiles)
                assertEquals(a.choices, b.choices)
                assertEquals(first.next(), second.next())
            }
        }
    }

    @Test
    fun batchCoversEverySkill() {
        val hands = HandGenerator.batch(60)
        assertTrue(hands.size > 40)
        assertEquals(HandGenerator.generatableCategories.toSet(), hands.map { it.answer }.toSet())
    }

    @Test
    fun endlessItemsAreWellFormed() {
        for (skill in PracticeSkill.entries) {
            val items = EndlessPractice.items(skill, 12)
            assertEquals(12, items.size)
            for (item in items) {
                assertTrue(item.id.startsWith(skill.itemPrefix))
                assertEquals(skill, PracticeSkill.skill(item.id))
                assertTrue(item.choices.size >= 3)
                assertTrue(item.answerIndex in item.choices.indices)
                assertEquals(item.choices.size, item.choices.toSet().size)
                assertTrue(item.explanation.isNotEmpty())
                assertNotNull(DrillLibrary.room(item.roomID))
            }
        }
    }

    @Test
    fun trickItemsDescribeLegalChoices() {
        for (item in EndlessPractice.items(PracticeSkill.TRICK_PLAY, 40)) {
            val card = item.tiles.single() as PlayingCard.Standard
            assertTrue(card.rank in 7..14)
            assertTrue("Angespielte Farbe" in item.prompt)
            val lead = Suit.entries.first { item.prompt.startsWith("Angespielte Farbe: ${it.displayName}.") }
            val expected = if (card.suit == lead) "Die angespielte Farbe bedienen" else "Eine Karte deiner Wahl spielen"
            assertEquals(expected, item.choices[item.answerIndex])
        }
    }

    @Test
    fun mixedItemsDrawFromEverySkill() {
        val items = EndlessPractice.mixedItems(40)
        assertEquals(40, items.size)
        assertEquals(PracticeSkill.entries.toSet(), items.mapNotNull { PracticeSkill.skill(it.id) }.toSet())
    }

    // MARK: - iOS SkatMinuteContentTests

    @Test
    fun challengeIsStableAndHasTheFiveQuestionMix() {
        val day = LocalDate.of(2026, 8, 9)
        val first = SkatMinuteContent.challenge(day)
        val second = SkatMinuteContent.challenge(day)
        assertEquals("2026-08-09", first.dayKey)
        assertEquals(first.items, second.items)
        val counts = first.questions.groupingBy { it.category }.eachCount()
        assertEquals(SkatMinuteContent.QUESTION_COUNT, first.questions.size)
        assertEquals(2, counts[SkatMinuteCategory.HAND_READING])
        assertEquals(1, counts[SkatMinuteCategory.DRUECKEN])
        assertEquals(2, counts[SkatMinuteCategory.STICHSPIEL])
        for (question in first.questions) {
            val item = question.item
            assertTrue(item.choices.size >= 2)
            assertTrue(item.answerIndex in item.choices.indices)
            assertTrue(item.explanation.isNotEmpty() && "\u2014" !in item.explanation)
        }
        for (question in first.questions.filter { it.category == SkatMinuteCategory.HAND_READING }) {
            assertFalse(question.item.isReviewable)
            assertEquals(PracticeSkill.HAND_READING.raw, question.item.trackingID)
        }
    }

    /** A day that fails to deal fails for every player at once, so sweep five years of day keys. */
    @Test
    fun everyDaySeedDealsTheFullQuestionSet() {
        var day = LocalDate.of(2026, 1, 1)
        var checked = 0
        while (day.isBefore(LocalDate.of(2031, 1, 1))) {
            val key = SkatMinuteContent.key(day)
            assertEquals(key, 2, HandGenerator.batch(2, "skat-minute-$key-hands").size)
            checked += 1
            day = day.plusDays(1)
        }
        assertTrue(checked > 1800)
    }
}
