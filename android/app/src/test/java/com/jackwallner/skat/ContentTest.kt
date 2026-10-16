package com.jackwallner.skat

import com.jackwallner.skat.content.DrillLibrary
import com.jackwallner.skat.content.EndlessPractice
import com.jackwallner.skat.content.HowToPlayContent
import com.jackwallner.skat.content.PracticeSkill
import com.jackwallner.skat.content.SessionBuilder
import com.jackwallner.skat.content.SkatContent
import com.jackwallner.skat.model.DiscardScenario
import com.jackwallner.skat.model.DrillKind
import com.jackwallner.skat.model.Flashcard
import com.jackwallner.skat.model.HandCategory
import com.jackwallner.skat.model.HandMatchQuestion
import com.jackwallner.skat.model.PlayingCard
import com.jackwallner.skat.model.QuizQuestion
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Port of iOS `ContentValidityTests` and the content half of `AdvancedContentTests`. */
class ContentTest {
    private val drills = DrillLibrary.rooms.flatMap { it.drills }
    private val handMatch: List<HandMatchQuestion> = drills.flatMap { (it.kind as? DrillKind.HandMatch)?.questions.orEmpty() }
    private val quiz: List<QuizQuestion> = drills.flatMap { (it.kind as? DrillKind.Quiz)?.questions.orEmpty() }
    private val discards: List<DiscardScenario> = drills.flatMap { (it.kind as? DrillKind.Discard)?.scenarios.orEmpty() }
    private val flashcards: List<Flashcard> = drills.flatMap { (it.kind as? DrillKind.Flashcards)?.cards.orEmpty() }

    @Test
    fun countsMatchIos() {
        val expected = ParityFixtures.json.getJSONObject("drillCounts")
        assertEquals(expected.length(), drills.size)
        for (drill in drills) assertEquals(drill.id, expected.getInt(drill.id), drill.kind.itemCount)
        assertEquals(listOf("card-room", "scoring-room", "discard-room", "pegging-room", "pro-tables"), DrillLibrary.rooms.map { it.id })
        assertEquals(ParityFixtures.json.getInt("lockedDrillCount"), DrillLibrary.rooms.sumOf { it.plusDrillCount })
        assertEquals(HandCategory.entries.size, SkatContent.library.categoryText.size)
        assertEquals(6, HowToPlayContent.pages.size)
        // iOS AdvancedContentTests: the catalog size and the 100-item master room.
        assertTrue(drills.sumOf { it.kind.itemCount } >= 222)
        assertEquals(100, DrillLibrary.room("pro-tables")!!.drills.sumOf { it.kind.itemCount })
    }

    @Test
    fun handMatchQuestionsShowFiveDistinctCards() {
        for (question in handMatch) {
            assertEquals(question.id, 5, question.tiles.size)
            assertEquals(question.id, 5, question.tiles.toSet().size)
        }
    }

    @Test
    fun handMatchAnswerIsAmongDistinctChoices() {
        for (question in handMatch) {
            assertTrue(question.id, question.answer in question.choices)
            assertEquals(question.id, question.choices.size, question.choices.toSet().size)
        }
    }

    @Test
    fun discardDealsHaveTwelveSkatCardsAndRecommendTwo() {
        for (scenario in discards) {
            assertEquals(scenario.id, 12, scenario.deal.size)
            assertEquals(scenario.id, 2, scenario.recommendedDiscard.size)
            assertEquals(scenario.id, 12, scenario.deal.toSet().size)
            assertEquals(scenario.id, 2, scenario.recommendedDiscard.toSet().size)
            assertTrue(scenario.id, scenario.deal.containsAll(scenario.recommendedDiscard))
            assertTrue(scenario.id, scenario.deal.all { it is PlayingCard.Standard && it.rank in 7..14 })
            assertTrue(scenario.id, "Lehrziel:" in scenario.situation)
        }
    }

    @Test
    fun quizAndCardChoicesAreValid() {
        for (question in quiz) {
            assertTrue(question.id, question.answerIndex in question.choices.indices)
            assertTrue(question.id, question.choices.size >= 2)
            assertEquals(question.id, question.choices.size, question.choices.toSet().size)
        }
        for (card in flashcards) {
            val choice = card.choice ?: continue
            assertEquals(card.id, 2, choice.options.size)
            assertTrue(card.id, choice.answerIndex in choice.options.indices)
            assertEquals(card.id, 2, choice.options.toSet().size)
        }
    }

    @Test
    fun allShownCardsAreUniqueAndBelongToTheSkatDeck() {
        for (drill in drills) {
            val hands = when (val kind = drill.kind) {
                is DrillKind.Quiz -> kind.questions.map { it.tiles }
                is DrillKind.Flashcards -> kind.cards.map { it.frontTiles }
                is DrillKind.HandMatch -> kind.questions.map { it.tiles }
                is DrillKind.Discard -> kind.scenarios.map { it.deal }
            }
            for (hand in hands) {
                assertEquals(drill.id, hand.size, hand.toSet().size)
                assertTrue(drill.id, hand.all { it is PlayingCard.Standard && it.rank in 7..14 })
            }
        }
    }

    @Test
    fun expertQuizzesHaveExplicitSituationAndReasoning() {
        for (drill in DrillLibrary.room("pro-tables")!!.drills) {
            val questions = (drill.kind as? DrillKind.Quiz)?.questions ?: continue
            for (question in questions) {
                assertTrue(question.id, question.prompt.length > 65)
                assertTrue(question.id, question.explanation.length > 80)
                assertEquals(question.id, 3, question.choices.size)
                assertFalse(question.id, question.id.startsWith("meister-"))
                assertFalse(question.id, question.id.startsWith("mehr-regel-"))
            }
        }
    }

    @Test
    fun appliedPracticeStaysFree() {
        for (drillID in listOf("applied-bidding", "applied-tricks")) {
            val room = DrillLibrary.rooms.first { room -> room.drills.any { it.id == drillID } }
            val drill = room.drills.first { it.id == drillID }
            assertFalse(room.isLocked(drill, isMember = false))
            assertEquals(12, drill.kind.itemCount)
        }
    }

    @Test
    fun allContentIDsAreUnique() {
        val ids = DrillLibrary.rooms.flatMap { room ->
            listOf(room.id) + room.drills.flatMap { drill ->
                listOf(drill.id) + when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Discard -> kind.scenarios.map { it.id }
                }
            }
        }
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun freeBeginnerModelIsIntact() {
        assertTrue(DrillLibrary.rooms.first().isFree)
        for (room in DrillLibrary.rooms) {
            assertTrue(room.id, room.drills.isNotEmpty())
            for (drill in room.drills) assertTrue(drill.id, drill.kind.itemCount > 0)
            if (room.id == "pro-tables") {
                assertFalse(room.isFree)
            } else {
                assertTrue(room.isFree)
                assertEquals(room.id, 1, room.drills.count { it.isPlus })
            }
            for (drill in room.drills) {
                assertFalse(room.isLocked(drill, isMember = true))
                assertEquals(!room.isFree || drill.isPlus, room.isLocked(drill, isMember = false))
            }
        }
    }

    private val playerFacingCopy: List<String> by lazy {
        val copy = mutableListOf<String>()
        for (room in DrillLibrary.rooms) {
            copy += listOf(room.name, room.tagline)
            for (drill in room.drills) {
                copy += listOf(drill.title, drill.subtitle)
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.forEach {
                        copy += listOf(it.frontTitle, it.frontSubtitle.orEmpty(), it.backTitle, it.backBody) + it.choice?.options.orEmpty()
                    }
                    is DrillKind.Quiz -> kind.questions.forEach { copy += listOf(it.prompt, it.explanation) + it.choices }
                    is DrillKind.HandMatch -> kind.questions.forEach { copy += it.explanation }
                    is DrillKind.Discard -> kind.scenarios.forEach { copy += listOf(it.situation, it.reasoning, it.tip) }
                }
            }
        }
        HowToPlayContent.pages.forEach { copy += listOf(it.title, it.body, it.tip.orEmpty()) }
        copy += HandCategory.entries.map { it.howToSpot }
        copy
    }

    @Test
    fun noEmDashesOrStaleSourceGameCopy() {
        val stale = listOf("crib" + "bage", "pegging", "mah" + "j")
        for (text in playerFacingCopy) {
            assertFalse("Em dash: $text", "\u2014" in text)
            for (word in stale) assertFalse("Stale copy: $text", text.contains(word, ignoreCase = true))
        }
    }

    /** Null runs Ass, König, Dame, Bube, Zehn: "die normale Reihenfolge" is wrong there. */
    @Test
    fun nullCopyNeverClaimsTheNormalCardOrder() {
        for (text in playerFacingCopy.filter { it.contains("null", ignoreCase = true) }) {
            assertFalse(text, text.contains("normale Reihenfolge", ignoreCase = true))
            assertFalse(text, text.contains("normale Kartenreihenfolge", ignoreCase = true))
        }
    }

    @Test
    fun handGameCopyNeverClaimsADiscard() {
        for (text in playerFacingCopy.filter { it.contains("handspiel", ignoreCase = true) }) {
            assertFalse(text, text.contains("drückt zwei", ignoreCase = true))
        }
    }

    @Test
    fun coreSkatValuesAreTaughtSomewhere() {
        val corpus = playerFacingCopy.joinToString("\n")
        for (fact in listOf("Karo 9", "Herz 10", "Pik 11", "Kreuz 12", "24", "23", "18", "61")) {
            assertTrue("No drill teaches $fact", fact in corpus)
        }
        assertTrue(corpus.contains("Spitzen", ignoreCase = true))
    }

    @Test
    fun generatedTrickItemsNeverDealAJack() {
        val items = EndlessPractice.items(PracticeSkill.TRICK_PLAY, 400)
        assertEquals(400, items.size)
        for (item in items) assertFalse(item.prompt, item.tiles.any { it.isJack })
    }

    @Test
    fun primerPagesHaveUniqueIDsAndDistinctCards() {
        val pages = HowToPlayContent.pages
        assertEquals(pages.size, pages.map { it.id }.toSet().size)
        for (page in pages) assertEquals(page.id, page.tiles.size, page.tiles.toSet().size)
        assertEquals("card-room", HowToPlayContent.recommendedRoom("new").id)
        assertEquals("discard-room", HowToPlayContent.recommendedRoom("basics").id)
        assertEquals("pegging-room", HowToPlayContent.recommendedRoom("played").id)
    }

    private val lockedItemIDs: Set<String> by lazy {
        DrillLibrary.rooms.flatMap { room ->
            room.drills.filter { room.isLocked(it, isMember = false) }.flatMap { drill ->
                when (val kind = drill.kind) {
                    is DrillKind.Flashcards -> kind.cards.map { it.id }
                    is DrillKind.Quiz -> kind.questions.map { it.id }
                    is DrillKind.HandMatch -> kind.questions.map { it.id }
                    is DrillKind.Discard -> kind.scenarios.map { it.id }
                }
            }
        }.toSet()
    }

    @Test
    fun quickSessionPullsTenAndPrioritizesMisses() {
        val mix = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false)
        assertEquals(10, mix.size)
        assertEquals(10, mix.map { it.id }.toSet().size)
        val missed = mix[0].id
        assertTrue(SessionBuilder.quickSession(seen = setOf(missed), missed = setOf(missed), includePro = false).any { it.id == missed })
    }

    @Test
    fun quickSessionRespectsThePaidBoundary() {
        assertTrue(lockedItemIDs.isNotEmpty())
        val free = SessionBuilder.quickSession(200, emptySet(), emptySet(), includePro = false)
        for (item in free) assertFalse("${item.id} leaked", item.id in lockedItemIDs)
        val member = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        assertTrue(member.any { it.id in lockedItemIDs })
        val freeIDs = ParityFixtures.json.getJSONArray("freePoolIDs").strings().toSet()
        assertEquals(freeIDs, free.map { it.id }.toSet())
    }

    @Test
    fun quickSessionItemsAreChoiceOnly() {
        val plainCards = flashcards.filter { it.choice == null }.map { it.id }.toSet()
        val discardIDs = discards.map { it.id }.toSet()
        for (item in SessionBuilder.quickSession(200, emptySet(), emptySet(), includePro = true)) {
            assertTrue(item.choices.size >= 2)
            assertTrue(item.answerIndex in item.choices.indices)
            assertFalse(item.id in plainCards)
            assertFalse(item.id in discardIDs)
        }
    }

    @Test
    fun gameNightPrepLeadsWithDueThenWeakestRoom() {
        val pool = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        val due = pool.first { it.roomID == "pro-tables" }.id
        val prep = SessionBuilder.gameNightPrep(seen = emptySet(), missed = emptySet(), dueIDs = listOf(due), weakestRoomID = "pegging-room")
        assertEquals(10, prep.size)
        assertEquals(due, prep.first().id)
        assertTrue(prep.drop(1).take(9).all { it.roomID == "pegging-room" })
    }

    @Test
    fun reviewSessionKeepsSchedulerOrderAndDropsLockedItems() {
        val member = SessionBuilder.quickSession(500, emptySet(), emptySet(), includePro = true)
        val locked = member.first { it.id in lockedItemIDs }.id
        val free = member.first { it.id !in lockedItemIDs }.id
        assertEquals(listOf(locked, free), SessionBuilder.reviewSession(listOf(locked, free), includePro = true).map { it.id })
        assertEquals(listOf(free), SessionBuilder.reviewSession(listOf(locked, free), includePro = false).map { it.id })
    }
}
