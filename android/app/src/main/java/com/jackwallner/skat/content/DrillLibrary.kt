package com.jackwallner.skat.content

import com.jackwallner.skat.model.Room

object DrillLibrary {
    val rooms: List<Room> get() = SkatContent.library.rooms

    fun room(id: String): Room? = rooms.firstOrNull { it.id == id }

    /** The room a drill belongs to, so drill screens can report per-room accuracy. */
    fun roomID(forDrillID: String): String =
        rooms.firstOrNull { room -> room.drills.any { it.id == forDrillID } }?.id ?: ""
}

object HowToPlayContent {
    val pages: List<HowToPlayPage> get() = SkatContent.library.primer

    /** The room recommended at the end of the primer for an onboarding skill level. */
    fun recommendedRoom(skillLevel: String): Room {
        val roomID = when (skillLevel) {
            "played" -> "pegging-room"
            "basics" -> "discard-room"
            else -> "card-room"
        }
        return DrillLibrary.room(roomID) ?: DrillLibrary.rooms.first()
    }
}
