//
//  ImageCarouselCell.h
//  ImageCarousel
//
//  Created by 이승민 on 4/5/25.
//

#import "ImageCarouselView.h"
#import <React/RCTScrollView.h>
#import <SDWebImage/SDWebImage.h>

@interface ImageCarouselView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) NSTimeInterval elapsedTime;
@property (nonatomic, assign) BOOL isUserScrolling;
@property (nonatomic, assign) BOOL isLooping;
@property (nonatomic, assign) NSInteger lastReportedIndex;
@property (nonatomic, assign) NSTimeInterval lastIndexChangeTime;
@property (nonatomic, assign) BOOL isProgrammaticScroll;

@end

@implementation ImageCarouselView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self addSubview:self.collectionView];
    
    // Initialize flags
    self.isUserScrolling = NO;
    self.isLooping = NO;
    self.isProgrammaticScroll = NO;
    self.lastReportedIndex = -1;
    self.lastIndexChangeTime = 0;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  self.collectionView.frame = self.bounds;
  [self.collectionView.collectionViewLayout invalidateLayout];
  [self.collectionView reloadData];

  if (self.data.count > 0) {
    NSInteger originalCount = self.data.count / 3;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:originalCount inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
    
    // Initialize lastReportedIndex with the first item
    self.lastReportedIndex = 0;
    if (self.onChangeIndex) {
      self.onChangeIndex(@{@"index": @(0)});
    }
  }
}

- (void)setData:(NSArray<NSString *> *)data {
  if (data.count == 0) return;

  NSMutableArray *tripled = [NSMutableArray arrayWithCapacity:data.count * 3];
  for (int i = 0; i < 3; i++) {
    [tripled addObjectsFromArray:data];
  }

  _data = [tripled copy];
  [self.collectionView reloadData];

  dispatch_async(dispatch_get_main_queue(), ^{
    NSInteger originalCount = data.count;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:originalCount inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  });
}

- (void)setAutoPlay:(BOOL)autoPlay {
  _autoPlay = autoPlay;
  [self setupDisplayLink];
}

- (void)setInterval:(NSInteger)interval {
  _interval = interval;
  [self setupDisplayLink];
}

- (void)setupDisplayLink {
  [self.displayLink invalidate];
  self.displayLink = nil;
  self.elapsedTime = 0;
  self.lastUpdateTime = 0;

  if (self.autoPlay && self.data.count > 1) {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }
}

- (void)handleDisplayLink:(CADisplayLink *)displayLink {
  // Skip if user is actively scrolling
  if (self.isUserScrolling) {
    self.lastUpdateTime = displayLink.timestamp;
    return;
  }
  
  if (self.lastUpdateTime == 0) {
    self.lastUpdateTime = displayLink.timestamp;
    return;
  }
  
  NSTimeInterval deltaTime = displayLink.timestamp - self.lastUpdateTime;
  self.lastUpdateTime = displayLink.timestamp;
  self.elapsedTime += deltaTime;
  
  if (self.elapsedTime >= self.interval / 1000.0) {
    [self nextPage];
    self.elapsedTime = 0;
  }
}

- (void)nextPage {
  NSIndexPath *visibleIndex = [[self.collectionView indexPathsForVisibleItems] firstObject];
  if (!visibleIndex) return;

  NSInteger nextItem = visibleIndex.item + 1;
  if (nextItem >= self.data.count) return;

  [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:nextItem inSection:0]
                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                      animated:YES];
}

- (void)resetAutoPlayTimer {
  if (self.autoPlay) {
    [self setupDisplayLink];
  }
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.data.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

  // 이미지뷰 중복 제거
  for (UIView *sub in cell.contentView.subviews) {
    [sub removeFromSuperview];
  }

  NSString *urlStr = self.data[indexPath.item];
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
  imageView.contentMode = UIViewContentModeScaleAspectFill;
  imageView.clipsToBounds = YES;
  imageView.userInteractionEnabled = YES;

  if (urlStr && urlStr.length > 0) {
    NSURL *url = [NSURL URLWithString:urlStr];
    [imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed];
  }

  imageView.tag = indexPath.item;
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
  [imageView addGestureRecognizer:tap];

  [cell.contentView addSubview:imageView];
  return cell;
}

#pragma mark - UICollectionView Delegate

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.isUserScrolling = YES;
  self.isProgrammaticScroll = NO;
  
  // Cancel any pending notifications
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  // If the scroll was initiated by the user (not programmatic), ensure flag is set
  if (scrollView.isDragging || scrollView.isDecelerating) {
    self.isUserScrolling = YES;
  }
  
  // Cancel any pending index change notifications while scrolling
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyIndexChangeIfNeeded) object:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  // Add a small delay before processing to ensure stability
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self.isProgrammaticScroll) {
      self.isUserScrolling = NO;
      [self handleLoopingIfNeeded];
      [self resetAutoPlayTimer];
      self.elapsedTime = 0;
      [self performSelector:@selector(notifyIndexChangeIfNeeded) withObject:nil afterDelay:0.15];
    }
  });
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.isProgrammaticScroll = NO;
    self.isUserScrolling = NO;
    [self handleLoopingIfNeeded];
    [self resetAutoPlayTimer];
    self.elapsedTime = 0;
    [self performSelector:@selector(notifyIndexChangeIfNeeded) withObject:nil afterDelay:0.15];
  });
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.isUserScrolling = NO;
      [self handleLoopingIfNeeded];
      [self resetAutoPlayTimer];
      self.elapsedTime = 0;
      [self performSelector:@selector(notifyIndexChangeIfNeeded) withObject:nil afterDelay:0.15];
    });
  }
}

#pragma mark - Layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return collectionView.bounds.size;
}

#pragma mark - Looping

- (void)handleLoopingIfNeeded {
  // Prevent multiple simultaneous calls
  static BOOL isExecuting = NO;
  if (isExecuting) return;
  isExecuting = YES;
  
  NSIndexPath *visibleIndex = [[self.collectionView indexPathsForVisibleItems] firstObject];
  if (!visibleIndex) {
    isExecuting = NO;
    return;
  }
  
  NSInteger currentIndex = visibleIndex.item;
  NSInteger originalCount = self.data.count / 3;
  
  self.isLooping = YES;
  
  if (currentIndex < originalCount) {
    currentIndex += originalCount;
    self.isProgrammaticScroll = YES;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  } else if (currentIndex >= originalCount * 2) {
    currentIndex -= originalCount;
    self.isProgrammaticScroll = YES;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  }
  
  // Wait a bit before clearing looping flag to prevent index notifications during the process
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    self.isLooping = NO;
    isExecuting = NO;
    if (!self.isUserScrolling) {
      [self notifyIndexChangeIfNeeded];
    }
  });
}

#pragma mark - Tap

- (void)handleImageTap:(UITapGestureRecognizer *)gesture {
  UIView *view = gesture.view;
  if (![view isKindOfClass:[UIImageView class]]) return;

  NSInteger originalCount = self.data.count / 3;
  NSInteger index = view.tag % originalCount;
  
  // Update lastReportedIndex to maintain consistency
  self.lastReportedIndex = index;
  
  if (self.onPressImage) {
    self.onPressImage(@{@"index": @(index)});
  }
}

- (void)scrollToIndex:(NSInteger)index {
  NSInteger originalCount = self.data.count / 3;
  if (index < 0 || index >= originalCount) return;

  NSInteger targetIndex = index + originalCount;
  
  // Update lastReportedIndex immediately to prevent jumps
  self.lastReportedIndex = index;
  
  // Mark as programmatic scroll
  self.isProgrammaticScroll = YES;
  self.isUserScrolling = NO;
  
  [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                      animated:YES];
  [self resetAutoPlayTimer];
  self.elapsedTime = 0;
  
  // Force notify the index change
  if (self.onChangeIndex) {
    self.onChangeIndex(@{@"index": @(index)});
  }
}

- (void)notifyIndexChangeIfNeeded {
  // Skip if we're in looping process or user is scrolling
  if (self.isLooping || self.isUserScrolling) {
    return;
  }
  
  NSIndexPath *visibleIndex = [[self.collectionView indexPathsForVisibleItems] firstObject];
  if (!visibleIndex) return;

  NSInteger originalCount = self.data.count / 3;
  NSInteger calculatedIndex = visibleIndex.item % originalCount;
  
  // Debounce index changes to prevent rapid consecutive reports
  NSTimeInterval currentTime = CACurrentMediaTime();
  BOOL shouldDebounce = (currentTime - self.lastIndexChangeTime) < 0.3;
  
  // Only fire if index actually changed and we're not in a transition state
  if (calculatedIndex != self.lastReportedIndex && !shouldDebounce) {
    self.lastReportedIndex = calculatedIndex;
    self.lastIndexChangeTime = currentTime;
    
    if (self.onChangeIndex) {
      self.onChangeIndex(@{@"index": @(calculatedIndex)});
    }
  }
}

- (void)dealloc {
  [self.displayLink invalidate];
  self.displayLink = nil;
}

@end
