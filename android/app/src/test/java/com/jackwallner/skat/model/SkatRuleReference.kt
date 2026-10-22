package com.jackwallner.skat.model

/** ISkO 2.2-2.6, 3.6 and 4.2/4.3. null trump means Grand. */
object SkatRuleReference {
    fun isTrump(card: PlayingCard, trump: Suit?, nullGame: Boolean = false) =
        !nullGame && (card.isJack || trump != null && card.suit == trump)
    fun legal(hand: List<PlayingCard>, led: PlayingCard, trump: Suit?, nullGame: Boolean = false): List<PlayingCard> =
        hand.filter { if (isTrump(led, trump, nullGame)) isTrump(it, trump, nullGame)
            else !isTrump(it, trump, nullGame) && it.suit == led.suit }.ifEmpty { hand }
    fun winner(trick: List<PlayingCard>, trump: Suit?, nullGame: Boolean = false): Int? {
        val led = trick.firstOrNull() ?: return null
        fun strength(card: PlayingCard): Int {
            if (isTrump(card, trump, nullGame)) {
                if (card.isJack) return 200 - Suit.entries.indexOf(card.suit)
                return 100 + listOf(7, 8, 9, 12, 13, 10, 14).indexOf(card.rankValue)
            }
            if (isTrump(led, trump, nullGame) || card.suit != led.suit) return 0
            return 10 + if (nullGame) card.rankValue else listOf(7, 8, 9, 12, 13, 10, 14).indexOf(card.rankValue)
        }
        return trick.indices.maxByOrNull { strength(trick[it]) }
    }
    fun matadors(cardsIncludingSkat: List<PlayingCard>, trump: Suit?): Int {
        val order = listOf(PlayingCard.c(11), PlayingCard.s(11), PlayingCard.h(11), PlayingCard.d(11)) +
            if (trump == null) emptyList() else listOf(14, 10, 13, 12, 9, 8, 7).map { PlayingCard.Standard(it, trump) }
        val withTop = order.first() in cardsIncludingSkat
        return order.takeWhile { (it in cardsIncludingSkat) == withTop }.size
    }
    fun score(base: Int, matadors: Int, hand: Boolean = false, points: Int, tricks: Int, bid: Int,
        schneider: Boolean = false, schwarz: Boolean = false, ouvert: Boolean = false): Int? {
        if (!hand && (schneider || schwarz || ouvert)) return null
        val schneiderAnnounced = schneider || schwarz || ouvert
        val schwarzAnnounced = schwarz || ouvert
        val schneiderStage = schneiderAnnounced || points <= 30 || points >= 90
        val schwarzStage = schwarzAnnounced || tricks == 0 || tricks == 10
        val stages = (if (schneiderStage) 1 else 0) + (if (schneiderAnnounced) 1 else 0) +
            (if (schwarzStage) 1 else 0) + (if (schwarzAnnounced) 1 else 0) + (if (ouvert) 1 else 0)
        val value = base * (matadors + 1 + (if (hand) 1 else 0) + stages)
        val win = points >= 61 && (!(schneider || schwarz || ouvert) || points >= 90) && (!(schwarz || ouvert) || tricks == 10) && value >= bid
        return if (win) value else -2 * maxOf(value, ((bid + base - 1) / base) * base)
    }
    fun nullScore(hand: Boolean, ouvert: Boolean, tricks: Int, bid: Int): Int? {
        val value = if (ouvert) { if (hand) 59 else 46 } else { if (hand) 35 else 23 }
        if (bid > value) return null
        return if (tricks == 0) value else -2 * value
    }
}
