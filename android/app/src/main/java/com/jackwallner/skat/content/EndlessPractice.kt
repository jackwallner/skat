package com.jackwallner.skat.content

import com.jackwallner.skat.model.Drill
import com.jackwallner.skat.model.DrillKind
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.Suit
import java.util.UUID

/** Generated practice skills. Each one becomes the same QuickItem shape as authored drills. */
enum class PracticeSkill(val raw: String, val title: String, val subtitle: String, val icon: String, val roomID: String) {
    HAND_READING("handReading", "Handmuster lesen", "Frische Kartenmuster, unbegrenzt", "rectangle.portrait.on.rectangle.portrait.angled", "scoring-room"),
    TRICK_PLAY("trickPlay", "Stichspiel üben", "Bedienpflicht und Stichentscheidung", "arrow.up.right.circle.fill", "pegging-room");

    /** Every generated item carries this prefix so stats roll it up into one row. */
    val itemPrefix: String get() = "gen-$raw-"

    companion object {
        fun fromRaw(raw: String): PracticeSkill? = entries.firstOrNull { it.raw == raw }

        fun skill(forItemID: String): PracticeSkill? = entries.firstOrNull { forItemID.startsWith(it.itemPrefix) }
    }
}

object EndlessPractice {
    fun drill(skill: PracticeSkill) = Drill("endless-${skill.raw}", skill.title, skill.subtitle, DrillKind.Quiz(emptyList()))

    val challengeDrill = Drill(
        "timed-challenge",
        "Zeitprüfung",
        "90 Sekunden, so viele sichere Entscheidungen wie möglich",
        DrillKind.Quiz(emptyList()),
    )

    fun items(skill: PracticeSkill, count: Int): List<QuickItem> = when (skill) {
        PracticeSkill.HAND_READING -> handItems(count)
        PracticeSkill.TRICK_PLAY -> trickItems(count)
    }

    /** A mixed batch across every skill, for the timed challenge. */
    fun mixedItems(count: Int): List<QuickItem> {
        val skills = PracticeSkill.entries
        val perSkill = maxOf(1, count / skills.size + 1)
        return skills.flatMap { items(it, perSkill) }.shuffled().take(count)
    }

    private fun newID(skill: PracticeSkill) = skill.itemPrefix + UUID.randomUUID().toString().uppercase()

    private fun handItems(count: Int): List<QuickItem> = HandGenerator.batch(count).map { hand ->
        QuickItem(
            id = newID(PracticeSkill.HAND_READING),
            prompt = "Welche Struktur fällt dir zuerst auf?",
            tiles = hand.tiles,
            choices = hand.choices.map { it.displayName },
            answerIndex = hand.choices.indexOf(hand.answer).coerceAtLeast(0),
            explanation = hand.explanation,
            sourceLabel = "Endlos üben",
            roomID = PracticeSkill.HAND_READING.roomID,
        )
    }

    /**
     * Never deals a Bube: this drill decides Bedienpflicht by printed suit, and
     * in a Farbspiel or Grand a Bube is trump, not part of its printed suit.
     */
    private fun trickItems(count: Int): List<QuickItem> {
        val ranks = PlayingCard.skatRanks.filter { it != 11 }
        val items = mutableListOf<QuickItem>()
        while (items.size < count) {
            val lead = Suit.entries.random()
            val card = PlayingCard.Standard(ranks.random(), Suit.entries.random())
            val follows = card.suit == lead
            val choices: List<String>
            val explanation: String
            if (follows) {
                choices = listOf("Die angespielte Farbe bedienen", "Eine andere Farbe spielen", "Ohne Grund trumpfen")
                explanation = "Du hältst ${card.spokenName}, also eine Karte der angespielten Farbe ${lead.displayName}. Die Bedienpflicht geht vor."
            } else {
                choices = listOf("Eine Karte deiner Wahl spielen", "Die angespielte Farbe bedienen", "Den Stich neu geben lassen")
                explanation = "${card.spokenName} gehört nicht zur angespielten Farbe ${lead.displayName}. Wenn du die Farbe nicht bedienen kannst, darfst du frei wählen."
            }
            items += QuickItem(
                id = newID(PracticeSkill.TRICK_PLAY),
                prompt = "Angespielte Farbe: ${lead.displayName}. Du hältst ${card.spokenName}. Was ist richtig?",
                tiles = listOf(card),
                choices = choices,
                answerIndex = 0,
                explanation = explanation,
                sourceLabel = "Endlos üben",
                roomID = PracticeSkill.TRICK_PLAY.roomID,
            )
        }
        return items
    }
}
