package com.jackwallner.skat

import com.jackwallner.skat.content.DrillLibrary
import com.jackwallner.skat.content.HowToPlayContent
import com.jackwallner.skat.model.DrillKind
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.SkatRuleReference
import com.jackwallner.skat.model.Suit
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RulesAuditTest {
    private fun card(code: String) = PlayingCard.Standard(code.drop(1).toInt(),
        mapOf('C' to Suit.CLUBS, 'D' to Suit.DIAMONDS, 'H' to Suit.HEARTS, 'S' to Suit.SPADES).getValue(code.first()))
    private fun reference() = JSONObject(javaClass.getResourceAsStream("/rules-reference.json")!!.bufferedReader().readText())
    private fun trump(row: JSONObject): Suit? = if (row.isNull("trump")) null else Suit.entries.first { it.raw == row.getString("trump") }

    @Test fun cardValuesAndTrumpCounts() {
        for ((rank, value) in listOf(7 to 0, 8 to 0, 9 to 0, 10 to 10, 11 to 2, 12 to 3, 13 to 4, 14 to 11))
            for (suit in Suit.entries) assertEquals(value, PlayingCard.Standard(rank, suit).skatValue)
        val deck = Suit.entries.flatMap { suit -> (7..14).map { PlayingCard.Standard(it, suit) } }
        assertEquals(120, deck.sumOf { it.skatValue })
        for (suit in Suit.entries) assertEquals(11, deck.count { SkatRuleReference.isTrump(it, suit) })
        assertEquals(4, deck.count { SkatRuleReference.isTrump(it, null) })
        assertEquals(0, deck.count { SkatRuleReference.isTrump(it, null, true) })
    }
    @Test fun followingAndTrickAnswersUseDisplayedCards() {
        val drills = DrillLibrary.rooms.flatMap { it.drills }
        val flashcards = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }.associateBy { it.id }
        val quizzes = drills.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }.associateBy { it.id }
        for (r in reference().getJSONArray("legal").objects()) {
            val id = r.getString("id")
            val hand = r.getJSONArray("hand").strings().map(::card)
            val shown = quizzes[id]?.tiles ?: flashcards.getValue(id).frontTiles
            assertEquals(id, hand, shown)
            assertEquals(id, r.getJSONArray("expected").strings().map(::card), SkatRuleReference.legal(shown, card(r.getString("led")), trump(r), r.getBoolean("null")))
        }
        for (r in reference().getJSONArray("tricks").objects()) {
            val q = quizzes.getValue(r.getString("id"))
            assertEquals(r.getJSONArray("cards").strings().map(::card), q.tiles)
            val winner = SkatRuleReference.winner(q.tiles, trump(r), r.getBoolean("null"))!!
            assertEquals(r.getInt("winner"), winner)
            val c = q.tiles[winner]
            val rank = mapOf(10 to "Zehn", 11 to "Bube", 13 to "König", 14 to "Ass").getValue(c.rankValue)
            assertEquals("${c.suit!!.displayName}-$rank", q.choices[q.answerIndex])
        }
    }
    @Test fun matadorsIncludeSkatAndContinueBeyondJacks() {
        for (r in reference().getJSONArray("matadors").objects())
            assertEquals(r.getInt("expected"), SkatRuleReference.matadors(r.getJSONArray("cards").strings().map(::card), trump(r)))
    }
    @Test fun iskoScoringThresholdsAnnouncementsAndOverbids() {
        val quizzes = DrillLibrary.rooms.flatMap { it.drills }.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }.associateBy { it.id }
        for (r in reference().getJSONArray("scores").objects()) {
            val actual = SkatRuleReference.score(r.getInt("base"), r.getInt("matadors"), r.getBoolean("hand"), r.getInt("points"), r.getInt("tricks"), r.getInt("bid"), r.getBoolean("schneider"), r.getBoolean("schwarz"), r.getBoolean("ouvert"))
            assertEquals(r.getString("id"), r.getInt("expected"), actual)
            quizzes[r.getString("id")]?.let { assertEquals(actual.toString(), it.choices[it.answerIndex]) }
        }
        for ((hand, ouvert, expected) in listOf(Triple(false, false, 23), Triple(true, false, 35), Triple(false, true, 46), Triple(true, true, 59))) {
            assertEquals(expected, SkatRuleReference.nullScore(hand, ouvert, 0, 18))
            assertEquals(-2 * expected, SkatRuleReference.nullScore(hand, ouvert, 1, 18))
        }
        assertNull(SkatRuleReference.score(24, 4, points = 120, tricks = 10, bid = 18, ouvert = true))
        val primer = HowToPlayContent.pages.first { it.id == "primer-reizen" }
        assertTrue(primer.body.contains("Wenn alle passen"))
        assertTrue(primer.body.contains("nächste Geber"))
    }
}
