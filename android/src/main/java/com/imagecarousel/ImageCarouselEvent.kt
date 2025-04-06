package com.imagecarousel

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class ImageCarouselEvent(
    surfaceId: Int,
    viewId: Int,
    private val eventName: String,
    private val eventData: WritableMap
) : Event<ImageCarouselEvent>(surfaceId, viewId) {

    override fun getEventName(): String = eventName

    override fun getEventData(): WritableMap? = eventData

    override fun getCoalescingKey(): Short = 0

    companion object {
        const val EVENT_NAME = "topChange"
    }
} 