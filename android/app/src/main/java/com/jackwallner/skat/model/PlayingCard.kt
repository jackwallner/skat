package com.jackwallner.skat.model

// Case order matches the iOS `allCases` order (Kreuz, Pik, Herz, Karo). The
// seeded generators walk these lists, so reordering a case changes every
// shared daily challenge.

enum class Suit(val raw: String, val symbol: String, val displayName: String) {
    CLUBS("clubs", "♣", "Kreuz"),
    SPADES("spades", "♠", "Pik"),
    HEARTS("hearts", "♥", "Herz"),
    DIAMONDS("diamonds", "♦", "Karo");

    val isRed: Boolean get() = this == DIAMONDS || this == HEARTS
}

sealed interface PlayingCard {
    data class Standard(val rank: Int, override val suit: Suit) : PlayingCard
    data object Joker : PlayingCard

    val shortLabel: String
        get() = when (this) {
            is Standard -> "${rankLabel(rank)}${suit.symbol}"
            Joker -> "Joker"
        }

    val spokenName: String
        get() = when (this) {
            is Standard -> "${rankName(rank)} ${suit.displayName}"
            Joker -> "Joker"
        }

    val suit: Suit? get() = null

    val rankValue: Int get() = (this as? Standard)?.rank ?: 0

    /** Card points used when counting tricks in a normal suit or Grand game. */
    val skatValue: Int
        get() = when ((this as? Standard)?.rank) {
            11 -> 2
            12 -> 3
            13 -> 4
            14 -> 11
            10 -> 10
            else -> 0
        }

    val isJack: Boolean get() = rankValue == 11

    val sortKey: Int
        get() = when (this) {
            is Standard -> suit.ordinal * 20 + rank
            Joker -> 100
        }

    /** The card's code in the exported content, e.g. `H11` for the Herz-Bube. */
    val code: String
        get() = when (this) {
            is Standard -> "${suit.raw.take(1).uppercase()}$rank"
            Joker -> "JK"
        }

    companion object {
        /** Sieben to Ass; the Ass is 14 so it sorts highest. */
        val skatRanks: List<Int> = (7..14).toList()

        fun c(rank: Int): PlayingCard = Standard(rank, Suit.CLUBS)
        fun s(rank: Int): PlayingCard = Standard(rank, Suit.SPADES)
        fun h(rank: Int): PlayingCard = Standard(rank, Suit.HEARTS)
        fun d(rank: Int): PlayingCard = Standard(rank, Suit.DIAMONDS)

        fun rankLabel(rank: Int): String = when (rank) {
            11 -> "B"
            12 -> "D"
            13 -> "K"
            14 -> "A"
            else -> rank.toString()
        }

        fun rankName(rank: Int): String = when (rank) {
            11 -> "Bube"
            12 -> "Dame"
            13 -> "König"
            14 -> "Ass"
            else -> rank.toString()
        }

        /** The 32-card Skat deck, suit by suit. */
        val skatDeck: List<PlayingCard> = Suit.entries.flatMap { suit -> skatRanks.map { Standard(it, suit) } }

        private val byCode: Map<String, PlayingCard> =
            (Suit.entries.flatMap { suit -> (1..14).map { Standard(it, suit) } } + Joker).associateBy { it.code }

        fun fromCode(code: String): PlayingCard = byCode[code] ?: error("Unknown card code $code")
    }
}

/** Sorted by suit then rank, the way the hand is fanned on screen. */
val List<PlayingCard>.racked: List<PlayingCard> get() = sortedBy { it.sortKey }
