package com.imagecarousel

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.FrameLayout
import androidx.viewpager2.widget.ViewPager2
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.EventDispatcher

class ImageCarouselView(context: Context) : FrameLayout(context) {
    private val viewPager = ViewPager2(context)
    private val handler = Handler(Looper.getMainLooper())
    private var timer: java.util.Timer? = null
    internal val reactContext = context as ReactContext

    private var images = listOf<String>()
    private var autoPlay = false
    private var interval = 3000L
    private var currentPosition = 0
    private val MULTIPLIER = 100000
    private var isResetting = false
    private var isUserScrolling = false

    companion object {
        const val EVENT_ON_CHANGE = "onChangeIndex"
        const val EVENT_ON_PRESS = "onPressImage"
    }

    init {
        viewPager.apply {
            orientation = ViewPager2.ORIENTATION_HORIZONTAL
            offscreenPageLimit = 1
            registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
                override fun onPageSelected(position: Int) {
                    if (!isResetting) {
                        val newIndex = position % images.size
                        if (currentPosition % images.size != newIndex) {
                            sendEvent(EVENT_ON_CHANGE, newIndex)
                        }
                        currentPosition = position
                        checkAndResetPosition()
                        if (!isUserScrolling && autoPlay) {
                            restartAutoScroll()
                        }
                    }
                }

                override fun onPageScrollStateChanged(state: Int) {
                    when (state) {
                        ViewPager2.SCROLL_STATE_DRAGGING -> {
                            isUserScrolling = true
                            stopAutoScroll()
                        }
                        ViewPager2.SCROLL_STATE_IDLE -> {
                            isResetting = false
                            if (isUserScrolling) {
                                isUserScrolling = false
                                if (autoPlay) {
                                    restartAutoScroll()
                                }
                            }
                        }
                    }
                }
            })
        }
        addView(viewPager)
    }

    private fun checkAndResetPosition() {
        if (images.isEmpty() || isResetting) return

        val itemCount = images.size
        val totalCount = itemCount * MULTIPLIER
        val middlePosition = (MULTIPLIER / 2) * itemCount
        val currentIndex = currentPosition % itemCount

        // 3사이클 = 이미지 개수 * 3
        val threshold = itemCount * 3

        val shouldReset = when {
            // 시작 지점에서 3사이클 전
            currentPosition < middlePosition &&
            (middlePosition - currentPosition) <= threshold -> true

            // 끝 지점에서 3사이클 전
            currentPosition > middlePosition &&
            (totalCount - currentPosition) <= threshold -> true

            else -> false
        }

        if (shouldReset) {
            isResetting = true
            handler.post {
                // 현재 보여지는 이미지와 동일한 이미지의 중간 위치로 이동
                val targetPosition = middlePosition + currentIndex
                viewPager.setCurrentItem(targetPosition, false)
                currentPosition = targetPosition
            }
        }
    }

    fun setData(data: List<String>) {
        images = data
        if (data.isEmpty()) return

        viewPager.adapter = ImageCarouselAdapter(data, MULTIPLIER) { position ->
            sendEvent(EVENT_ON_PRESS, position % data.size)
            if (autoPlay) {
                restartAutoScroll()
            }
        }

        val startPosition = (MULTIPLIER / 2) * data.size
        viewPager.setCurrentItem(startPosition, false)
        currentPosition = startPosition
    }

    fun setAutoPlay(enabled: Boolean) {
        autoPlay = enabled
        if (enabled) startAutoScroll() else stopAutoScroll()
    }

    fun setInterval(ms: Int) {
        interval = ms.toLong()
        if (autoPlay) {
            restartAutoScroll()
        }
    }

    fun scrollToIndex(index: Int) {
        if (index in images.indices) {
            val currentIndex = currentPosition % images.size
            val size = images.size

            // 정방향과 역방향 거리 계산
            val forwardDistance = if (index >= currentIndex) {
                index - currentIndex
            } else {
                size - currentIndex + index
            }

            val backwardDistance = if (index <= currentIndex) {
                currentIndex - index
            } else {
                currentIndex + (size - index)
            }

            // 더 짧은 거리로 이동
            val targetPosition = if (forwardDistance <= backwardDistance) {
                // 정방향 이동
                currentPosition + forwardDistance
            } else {
                // 역방향 이동
                currentPosition - backwardDistance
            }

            viewPager.setCurrentItem(targetPosition, true)
            if (autoPlay) {
                restartAutoScroll()
            }
        }
    }

    private fun startAutoScroll() {
        if (images.isEmpty()) return
        stopAutoScroll()

        timer = java.util.Timer().apply {
            schedule(object : java.util.TimerTask() {
                override fun run() {
                    handler.post {
                        if (!isResetting && !isUserScrolling) {
                            val nextPosition = currentPosition + 1
                            viewPager.setCurrentItem(nextPosition, true)
                            startAutoScroll()
                        }
                    }
                }
            }, interval)
        }
    }

    private fun stopAutoScroll() {
        timer?.cancel()
        timer = null
    }

    private fun restartAutoScroll() {
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({
            startAutoScroll()
        }, 100)
    }

    private fun sendEvent(eventName: String, index: Int) {
        val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(
            reactContext,
            id
        ) as? EventDispatcher ?: return

        val params = Arguments.createMap().apply {
            putInt("index", index)
        }

        val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
        val eventEmitter = ImageCarouselEvent(
            surfaceId,
            id,
            eventName,
            params
        )

        eventDispatcher.dispatchEvent(eventEmitter)
    }
}
