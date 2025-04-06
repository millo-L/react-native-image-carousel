#import "ImageCarouselViewManager.h"
#import "ImageCarouselView.h"
#import <React/RCTUIManager.h>

@implementation ImageCarouselViewManager

RCT_EXPORT_MODULE(ImageCarousel)

- (UIView *)view {
  return [[ImageCarouselView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(data, NSArray)
RCT_EXPORT_VIEW_PROPERTY(autoPlay, BOOL)
RCT_EXPORT_VIEW_PROPERTY(interval, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onPressImage, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onChangeIndex, RCTBubblingEventBlock)

RCT_EXPORT_METHOD(scrollToIndex:(nonnull NSNumber *)reactTag index:(NSInteger)index) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIView *view = [self.bridge.uiManager viewForReactTag:reactTag];
    if ([view isKindOfClass:[ImageCarouselView class]]) {
      [(ImageCarouselView *)view scrollToIndex:index];
    }
  });
}

@end
