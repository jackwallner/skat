package com.jackwallner.skat.content

import com.jackwallner.skat.model.HandCategory
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.RandomSource
import com.jackwallner.skat.model.StableSeededGenerator
import com.jackwallner.skat.model.Suit
import com.jackwallner.skat.model.SystemRandomSource
import com.jackwallner.skat.model.nextBool
import com.jackwallner.skat.model.racked
import com.jackwallner.skat.model.randomElement
import com.jackwallner.skat.model.shuffledSwift

/**
 * Port of iOS `HandGenerator`: original five-card teaching patterns for
 * generated Skat practice. Every draw comes from the RandomSource in the same
 * order as the Swift original, so a seeded batch deals the same cards as iOS
 * (`GeneratorParityTest`).
 */
object HandGenerator {
    val generatableCategories: List<HandCategory> =
        listOf(HandCategory.GRAND, HandCategory.TRUMPF, HandCategory.FARBE, HandCategory.NULLSPIEL, HandCategory.STICH)

    data class GeneratedHand(
        val tiles: List<PlayingCard>,
        val answer: HandCategory,
        val choices: List<HandCategory>,
        val explanation: String,
    )

    private fun ranks(cards: List<PlayingCard>): List<Int> = cards.mapNotNull { (it as? PlayingCard.Standard)?.rank }

    private fun jackCount(cards: List<PlayingCard>): Int = cards.count { it.isJack }

    private fun maximumSuitCount(cards: List<PlayingCard>): Int =
        cards.mapNotNull { it.suit }.groupingBy { it }.eachCount().values.maxOrNull() ?: 0

    private fun hasLowNullShape(cards: List<PlayingCard>): Boolean =
        jackCount(cards) == 0 && ranks(cards).all { it <= 10 } && maximumSuitCount(cards) < 4

    /** The checks intentionally describe mutually exclusive teaching reads. */
    fun fits(cards: List<PlayingCard>, category: HandCategory): Boolean {
        if (cards.size != 5 || cards.any { it.suit == null }) return false
        val jacks = jackCount(cards)
        val aces = ranks(cards).count { it == 14 }
        val suitCount = maximumSuitCount(cards)
        return when (category) {
            HandCategory.GRAND -> jacks >= 3
            HandCategory.TRUMPF -> jacks == 2 && suitCount >= 3
            HandCategory.FARBE -> jacks == 0 && suitCount >= 4
            HandCategory.NULLSPIEL -> hasLowNullShape(cards)
            HandCategory.STICH ->
                aces >= 2 && jacks < 3 && suitCount < 4 && !hasLowNullShape(cards) && !fits(cards, HandCategory.TRUMPF)
            else -> false
        }
    }

    fun category(cards: List<PlayingCard>): HandCategory? {
        val matches = generatableCategories.filter { fits(cards, it) }
        return if (matches.size == 1) matches[0] else null
    }

    private fun deal(target: HandCategory, source: RandomSource): List<PlayingCard>? {
        val cards: List<PlayingCard> = when (target) {
            HandCategory.GRAND -> listOf(
                PlayingCard.c(11), PlayingCard.s(11), PlayingCard.h(11), PlayingCard.d(11),
                PlayingCard.c(listOf(7, 8, 9, 10, 12, 13, 14).randomElement(source) ?: 7),
            )
            HandCategory.TRUMPF -> {
                val suit = if (source.nextBool()) Suit.HEARTS else Suit.DIAMONDS
                listOf(
                    PlayingCard.c(11), PlayingCard.s(11),
                    PlayingCard.Standard(7, suit), PlayingCard.Standard(10, suit), PlayingCard.Standard(14, suit),
                )
            }
            HandCategory.FARBE -> {
                val suit = Suit.entries.randomElement(source) ?: Suit.HEARTS
                listOf(7, 8, 9, 10, 14).map { PlayingCard.Standard(it, suit) }
            }
            HandCategory.NULLSPIEL -> listOf(PlayingCard.c(7), PlayingCard.d(8), PlayingCard.h(9), PlayingCard.s(10), PlayingCard.c(8))
            HandCategory.STICH -> listOf(PlayingCard.c(14), PlayingCard.d(14), PlayingCard.h(13), PlayingCard.s(12), PlayingCard.c(10))
            else -> return null
        }
        return if (category(cards) == target) cards else null
    }

    fun hand(target: HandCategory, attempts: Int = 120, source: RandomSource = SystemRandomSource): GeneratedHand? {
        repeat(attempts) {
            val cards = deal(target, source) ?: return@repeat
            if (category(cards) != target) return@repeat
            val distractors = generatableCategories
                .filter { it != target && !fits(cards, it) }
                .shuffledSwift(source)
                .take(3)
            if (distractors.size < 2) return@repeat
            return GeneratedHand(
                tiles = cards.racked,
                answer = target,
                choices = (listOf(target) + distractors).shuffledSwift(source),
                explanation = explain(cards, target),
            )
        }
        return null
    }

    fun batch(count: Int): List<GeneratedHand> = batch(count, SystemRandomSource)

    /** A reproducible batch: the same seed deals the same hands as iOS on every device. */
    fun batch(count: Int, seed: String): List<GeneratedHand> = batch(count, StableSeededGenerator(seed))

    private fun batch(count: Int, source: RandomSource): List<GeneratedHand> {
        val targets = mutableListOf<HandCategory>()
        while (targets.size < count) targets += generatableCategories.shuffledSwift(source)
        return targets.take(count).mapNotNull { hand(it, source = source) }.shuffledSwift(source)
    }

    fun explain(cards: List<PlayingCard>, answer: HandCategory): String {
        val labels = cards.racked.joinToString(", ") { it.shortLabel }
        return when (answer) {
            HandCategory.GRAND ->
                "In diesem Muster liegen mindestens drei Buben: $labels. Die vier Buben sind im Grand die einzigen Trümpfe."
            HandCategory.TRUMPF ->
                "Zwei Buben und mehrere Karten derselben Farbe geben hier eine klare Trumpfstruktur: $labels. Im Farbspiel zählen die Buben zusätzlich als Trumpf."
            HandCategory.FARBE ->
                "Vier oder mehr Karten gehören zu derselben Farbe: $labels. Das ist ein starkes Farbgefühl, auch wenn die konkrete Spielansage noch fehlt."
            HandCategory.NULLSPIEL ->
                "Die Karten sind niedrig, enthalten keinen Buben und verteilen sich auf mehrere Farben: $labels. Das passt zu einer Null-Idee."
            HandCategory.STICH ->
                "Zwei Asse und hohe Beikarten bilden eine sichere Stichstruktur: $labels. Den konkreten Stichwert prüfst du danach im Spielkontext."
            else -> answer.howToSpot
        }
    }
}
