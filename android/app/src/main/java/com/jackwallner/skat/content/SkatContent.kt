package com.jackwallner.skat.content

import com.jackwallner.skat.model.CardChoice
import com.jackwallner.skat.model.CategoryText
import com.jackwallner.skat.model.DiscardScenario
import com.jackwallner.skat.model.Drill
import com.jackwallner.skat.model.DrillKind
import com.jackwallner.skat.model.Flashcard
import com.jackwallner.skat.model.HandCategory
import com.jackwallner.skat.model.HandMatchQuestion
import com.jackwallner.skat.model.QuizQuestion
import com.jackwallner.skat.model.Room
import com.jackwallner.skat.model.PlayingCard
import org.json.JSONArray
import org.json.JSONObject

data class HowToPlayPage(
    val id: String,
    val icon: String,
    val title: String,
    val body: String,
    val tiles: List<PlayingCard>,
    val tip: String?,
)

data class WhatsNewItem(val id: String, val icon: String, val title: String, val body: String, val isPlus: Boolean)

data class WhatsNewRelease(val version: String, val headline: String, val items: List<WhatsNewItem>)

class ContentLibrary(
    val rooms: List<Room>,
    val categoryText: Map<HandCategory, CategoryText>,
    val primer: List<HowToPlayPage>,
    val whatsNew: List<WhatsNewRelease>,
)

/**
 * Every authored drill, the primer, the scoring categories and the release notes,
 * exported from the iOS sources by `scripts/sync-android-content.sh`. Loaded
 * from a classpath resource so JVM unit tests read exactly what the app reads.
 */
object SkatContent {
    val library: ContentLibrary by lazy { load() }

    private fun load(): ContentLibrary {
        val stream = SkatContent::class.java.classLoader!!.getResourceAsStream("skat-content.json")
            ?: error("skat-content.json is missing; run scripts/sync-android-content.sh")
        return parse(JSONObject(stream.bufferedReader().use { it.readText() }))
    }

    fun parse(json: JSONObject): ContentLibrary {
        val categories = json.getJSONArray("categories").objects().associate { item ->
            HandCategory.fromRaw(item.getString("id")) to CategoryText(
                displayName = item.getString("displayName"),
                shortName = item.getString("shortName"),
                howToSpot = item.getString("howToSpot"),
            )
        }
        return ContentLibrary(
            rooms = json.getJSONArray("rooms").objects().map(::room),
            categoryText = categories,
            primer = json.getJSONArray("primer").objects().map { item ->
                HowToPlayPage(
                    id = item.getString("id"),
                    icon = item.getString("icon"),
                    title = item.getString("title"),
                    body = item.getString("body"),
                    tiles = item.getJSONArray("tiles").tiles(),
                    tip = item.optStringOrNull("tip"),
                )
            },
            whatsNew = json.getJSONArray("whatsNew").objects().map { release ->
                WhatsNewRelease(
                    version = release.getString("version"),
                    headline = release.getString("headline"),
                    items = release.getJSONArray("items").objects().map { item ->
                        WhatsNewItem(
                            id = item.getString("id"),
                            icon = item.getString("icon"),
                            title = item.getString("title"),
                            body = item.getString("body"),
                            isPlus = item.getBoolean("isPlus"),
                        )
                    },
                )
            },
        )
    }

    private fun room(json: JSONObject) = Room(
        id = json.getString("id"),
        name = json.getString("name"),
        tagline = json.getString("tagline"),
        icon = json.getString("icon"),
        isFree = json.getBoolean("isFree"),
        drills = json.getJSONArray("drills").objects().map(::drill),
    )

    private fun drill(json: JSONObject): Drill {
        val items = json.getJSONArray("items").objects()
        val kind = when (val raw = json.getString("kind")) {
            "flashcards" -> DrillKind.Flashcards(items.map(::flashcard))
            "quiz" -> DrillKind.Quiz(items.map(::quiz))
            "handMatch" -> DrillKind.HandMatch(items.map(::handMatch))
            "discard" -> DrillKind.Discard(items.map(::discard))
            else -> error("Unknown drill kind $raw")
        }
        return Drill(
            id = json.getString("id"),
            title = json.getString("title"),
            subtitle = json.getString("subtitle"),
            kind = kind,
            isPlus = json.getBoolean("isPlus"),
        )
    }

    private fun flashcard(json: JSONObject) = Flashcard(
        id = json.getString("id"),
        frontTitle = json.getString("frontTitle"),
        frontTiles = json.getJSONArray("frontTiles").tiles(),
        frontSubtitle = json.optStringOrNull("frontSubtitle"),
        backTitle = json.getString("backTitle"),
        backBody = json.getString("backBody"),
        choice = json.optJSONObject("choice")?.let {
            CardChoice(it.getJSONArray("options").strings(), it.getInt("answerIndex"))
        },
    )

    private fun quiz(json: JSONObject) = QuizQuestion(
        id = json.getString("id"),
        prompt = json.getString("prompt"),
        tiles = json.getJSONArray("tiles").tiles(),
        choices = json.getJSONArray("choices").strings(),
        answerIndex = json.getInt("answerIndex"),
        explanation = json.getString("explanation"),
    )

    private fun handMatch(json: JSONObject) = HandMatchQuestion(
        id = json.getString("id"),
        tiles = json.getJSONArray("tiles").tiles(),
        choices = json.getJSONArray("choices").strings().map(HandCategory::fromRaw),
        answer = HandCategory.fromRaw(json.getString("answer")),
        explanation = json.getString("explanation"),
    )

    private fun discard(json: JSONObject) = DiscardScenario(
        id = json.getString("id"),
        situation = json.getString("situation"),
        deal = json.getJSONArray("deal").tiles(),
        recommendedDiscard = json.getJSONArray("recommendedDiscard").tiles(),
        reasoning = json.getString("reasoning"),
        tip = json.getString("tip"),
    )
}

internal fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }
internal fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }
internal fun JSONArray.tiles(): List<PlayingCard> = strings().map(PlayingCard::fromCode)
internal fun JSONObject.optStringOrNull(key: String): String? = if (has(key) && !isNull(key)) getString(key) else null
