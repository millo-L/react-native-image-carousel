package com.imagecarousel

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

class ImageCarouselViewManager : SimpleViewManager<ImageCarouselView>() {

  override fun getName(): String = "ImageCarousel"

  override fun createViewInstance(reactContext: ThemedReactContext): ImageCarouselView {
    return ImageCarouselView(reactContext)
  }

  @ReactProp(name = "data")
  fun setData(view: ImageCarouselView, data: ReadableArray?) {
    data?.toArrayList()?.mapNotNull { it as? String }?.let { images ->
      view.setData(images)
    }
  }

  @ReactProp(name = "autoPlay")
  fun setAutoPlay(view: ImageCarouselView, autoPlay: Boolean) {
    view.setAutoPlay(autoPlay)
  }

  @ReactProp(name = "interval")
  fun setInterval(view: ImageCarouselView, interval: Int) {
    view.setInterval(interval)
  }

  override fun getCommandsMap() = mapOf(
    "scrollToIndex" to 1
  )

  override fun receiveCommand(view: ImageCarouselView, commandId: Int, args: ReadableArray?) {
    if (commandId == 1) {
      val index = args?.getInt(0) ?: return
      view.scrollToIndex(index)
    }
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    return mapOf(
      ImageCarouselView.EVENT_ON_CHANGE to mapOf(
        "registrationName" to "onChangeIndex"
      ),
      ImageCarouselView.EVENT_ON_PRESS to mapOf(
        "registrationName" to "onPressImage"
      )
    )
  }
}
