//
//  ImageCarouselView.h
//  Pods
//
//  Created by 이승민 on 4/5/25.
//

#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@interface ImageCarouselView : UIView

@property (nonatomic, copy) NSArray<NSString *> *data;
@property (nonatomic, assign) BOOL autoPlay;
@property (nonatomic, assign) NSInteger interval;
@property (nonatomic, copy) RCTBubblingEventBlock onPressImage;
@property (nonatomic, copy) RCTBubblingEventBlock onChangeIndex;

- (void)scrollToIndex:(NSInteger)index;

@end
