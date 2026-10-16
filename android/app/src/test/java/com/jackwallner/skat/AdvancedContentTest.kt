package com.jackwallner.skat

import com.jackwallner.skat.content.DrillLibrary
import com.jackwallner.skat.model.DrillKind
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.PlayingCard.Companion.c
import com.jackwallner.skat.model.PlayingCard.Companion.d
import com.jackwallner.skat.model.PlayingCard.Companion.h
import com.jackwallner.skat.model.PlayingCard.Companion.s
import com.jackwallner.skat.model.QuizQuestion
import com.jackwallner.skat.model.Suit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Port of the rules half of iOS `AdvancedContentTests`: every expert answer is
 * re-derived independently (list values, trick-by-trick game trees, Null rank
 * order) against the content the Android app ships.
 */
class AdvancedContentTest {
    private val parity = ParityFixtures.json

    private fun quiz(drillID: String): List<QuizQuestion> =
        (DrillLibrary.rooms.flatMap { it.drills }.first { it.id == drillID }.kind as DrillKind.Quiz).questions

    @Test
    fun valueCasesMatchIndependentOverbidAndLossCalculation() {
        val cases = parity.getJSONArray("valueCases").objects()
        assertEquals(24, cases.size)
        val questions = quiz("master-counting").associateBy { it.id }
        for (lesson in cases) {
            val id = lesson.getString("id")
            val base = lesson.getInt("base")
            val bid = lesson.getInt("bid")
            val lost = lesson.getBoolean("lost")
            val achieved = base * lesson.getInt("multiplier")
            val minimumBidValue = ((bid + base - 1) / base) * base
            val expected = if (lost) -2 * maxOf(achieved, minimumBidValue) else achieved
            assertEquals(id, lesson.getInt("expected"), expected)
            val question = questions.getValue(id)
            assertEquals(id, expected.toString(), question.choices[question.answerIndex])
            if (!lost) assertTrue(id, achieved >= bid)
        }
    }

    @Test
    fun threeTrickPlanningAgainstEveryLegalDefense() {
        val cases = parity.getJSONArray("planningCases").objects()
        assertEquals(8, cases.size)
        val questions = quiz("master-three-tricks").associateBy { it.id }
        for (lesson in cases) {
            val id = lesson.getString("id")
            val hands = lesson.getJSONArray("hands").let { array -> (0 until array.length()).map { array.getJSONArray(it).cards() } }
            val trump = if (lesson.has("trump")) Suit.entries.first { it.raw == lesson.getString("trump") } else null
            val prior = lesson.getInt("priorEyes")
            assertEquals(id, listOf(3, 3, 3), hands.map { it.size })
            val all = hands.flatten()
            assertEquals(id, 9, all.toSet().size)
            assertTrue(id, prior + all.sumOf { it.skatValue } <= 120)
            val values = hands[0].map { pointsAfterLead(it, hands, trump) }
            assertEquals(id, lesson.getJSONArray("guaranteedEyes").ints(), values)
            val winners = values.indices.filter { values[it] + prior >= 61 }
            val question = questions.getValue(id)
            assertEquals(id, listOf(question.answerIndex), winners)
            assertEquals(id, 61, values.max() + prior)
            assertEquals(id, hands[0][winners[0]].spokenName, question.choices[question.answerIndex])
        }
    }

    @Test
    fun trumpFirstEndgamesAgainstEveryLegalDefense() {
        val positions: List<Triple<String, Suit?, List<List<PlayingCard>>>> = listOf(
            Triple("vertieft-ende-08", Suit.CLUBS, listOf(listOf(c(11), d(14)), listOf(c(7), h(10)), listOf(c(8), s(13)))),
            Triple("vertieft-ende-09", null, listOf(listOf(c(11), h(14)), listOf(s(11), s(10)), listOf(h(11), d(13)))),
            Triple("vertieft-ende-10", Suit.HEARTS, listOf(listOf(h(14), d(14)), listOf(h(10), s(13)), listOf(h(13), c(10)))),
        )
        val endgames = quiz("master-endgames").associateBy { it.id }
        for ((id, trump, hands) in positions) {
            assertEquals(id, hands[0], endgames.getValue(id).tiles)
            val all = hands.flatten()
            assertEquals(id, 6, all.toSet().size)
            val total = all.sumOf { it.skatValue }
            assertEquals(id, total, pointsAfterLead(hands[0][0], hands, trump))
            assertTrue(id, pointsAfterLead(hands[0][1], hands, trump) < total)
        }
    }

    @Test
    fun nullTacticsRespectTheirDifferentRankOrder() {
        val tactics = listOf(
            listOf("vertieft-null-04", listOf(s(7), s(10)), listOf(s(9), s(11)), s(9)),
            listOf("vertieft-null-05", listOf(d(8), d(12)), listOf(d(11), d(13)), d(11)),
            listOf("vertieft-null-12", listOf(c(9), c(10)), listOf(c(8), c(12)), c(8)),
            listOf("vertieft-null-20", listOf(s(7), s(9)), listOf(s(8), s(10)), s(8)),
        )
        val rankNames = mapOf(8 to "Acht", 9 to "Neun", 11 to "Bube")
        val nullPlay = quiz("master-rules").associateBy { it.id }
        for (row in tactics) {
            val id = row[0] as String
            @Suppress("UNCHECKED_CAST") val trick = row[1] as List<PlayingCard>
            @Suppress("UNCHECKED_CAST") val hand = row[2] as List<PlayingCard>
            val answer = row[3] as PlayingCard
            val winning = hand.filter { card ->
                (trick + card).withIndex().maxBy { it.value.rankValue }.index == 1
            }
            assertEquals(id, listOf(answer), winning)
            assertEquals(id, "${answer.suit!!.displayName}-${rankNames.getValue(answer.rankValue)}", nullPlay.getValue(id).choices.first())
        }
    }

    @Test
    fun pointMaximizingDiscardGoalsHaveUniqueSolutions() {
        val scenarios = (DrillLibrary.room("pro-tables")!!.drills.first { it.id == "master-discard" }.kind as DrillKind.Discard).scenarios
        for (index in listOf(0, 7)) {
            val scenario = scenarios[index]
            val protected = scenario.deal.filter {
                if (index == 0) it.isJack || it.rankValue == 14 else it.isJack || it.suit == Suit.CLUBS
            }
            val candidates = scenario.deal.filter { it !in protected }
            var best = -1
            var bestPairs = mutableListOf<Set<PlayingCard>>()
            for (i in candidates.indices) for (j in candidates.indices) {
                if (j <= i) continue
                val points = candidates[i].skatValue + candidates[j].skatValue
                if (points > best) {
                    best = points
                    bestPairs = mutableListOf()
                }
                if (points == best) bestPairs += setOf(candidates[i], candidates[j])
            }
            assertEquals(scenario.id, listOf(scenario.recommendedDiscard.toSet()), bestPairs)
        }
    }

    private fun pointsAfterLead(lead: PlayingCard, hands: List<List<PlayingCard>>, trump: Suit?): Int {
        val remaining = hands.toMutableList()
        remaining[0] = remaining[0] - lead
        return guaranteedPoints(remaining, listOf(lead), 0, trump)
    }

    private fun guaranteedPoints(hands: List<List<PlayingCard>>, trick: List<PlayingCard>, leader: Int, trump: Suit?): Int {
        if (trick.size == 3) {
            val lead = trick[0]
            val winnerOffset = trick.indices.maxBy { strength(trick[it], lead, trump) }
            val winner = (leader + winnerOffset) % 3
            val points = if (winner == 0) trick.sumOf { it.skatValue } else 0
            return points + guaranteedPoints(hands, emptyList(), winner, trump)
        }
        if (hands.all { it.isEmpty() }) return 0
        val player = (leader + trick.size) % 3
        val following = hands[player].filter { card ->
            val lead = trick.firstOrNull() ?: return@filter true
            if (isTrump(lead, trump)) isTrump(card, trump) else !isTrump(card, trump) && card.suit == lead.suit
        }
        val legal = following.ifEmpty { hands[player] }
        val outcomes = legal.map { card ->
            val remaining = hands.toMutableList()
            remaining[player] = remaining[player] - card
            guaranteedPoints(remaining, trick + card, leader, trump)
        }
        return if (player == 0) outcomes.max() else outcomes.min()
    }

    private fun isTrump(card: PlayingCard, suit: Suit?): Boolean = card.isJack || (suit != null && card.suit == suit)

    private fun strength(card: PlayingCard, lead: PlayingCard, trump: Suit?): Int {
        if (card.isJack) return 200 + (4 - Suit.entries.indexOf(card.suit!!))
        val rank = listOf(7, 8, 9, 12, 13, 10, 14).indexOf(card.rankValue)
        if (isTrump(card, trump)) return 100 + rank
        if (card.suit == lead.suit && !isTrump(lead, trump)) return 10 + rank
        return 0
    }
}
