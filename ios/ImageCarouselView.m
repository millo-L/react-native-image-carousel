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
@property (nonatomic, strong) NSTimer *timer;

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
  [self setupTimer];
}

- (void)setInterval:(NSInteger)interval {
  _interval = interval;
  [self setupTimer];
}

- (void)setupTimer {
  [self.timer invalidate];
  self.timer = nil;

  if (self.autoPlay && self.data.count > 1) {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.interval / 1000.0
                                                  target:self
                                                selector:@selector(nextPage)
                                                userInfo:nil
                                                 repeats:YES];
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
    [self setupTimer];
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [self handleLoopingIfNeeded];
  [self resetAutoPlayTimer];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  [self handleLoopingIfNeeded];
}

#pragma mark - Layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return collectionView.bounds.size;
}

#pragma mark - Looping

- (void)handleLoopingIfNeeded {
  NSIndexPath *visibleIndex = [[self.collectionView indexPathsForVisibleItems] firstObject];
  NSInteger currentIndex = visibleIndex.item;
  NSInteger originalCount = self.data.count / 3;

  if (currentIndex < originalCount) {
    currentIndex += originalCount;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  } else if (currentIndex >= originalCount * 2) {
    currentIndex -= originalCount;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:NO];
  }

  NSInteger displayIndex = currentIndex % originalCount;
  if (self.onChangeIndex) {
    self.onChangeIndex(@{@"index": @(displayIndex)});
  }
}

#pragma mark - Tap

- (void)handleImageTap:(UITapGestureRecognizer *)gesture {
  UIView *view = gesture.view;
  if (![view isKindOfClass:[UIImageView class]]) return;

  NSInteger index = view.tag % (self.data.count / 3);
  if (self.onPressImage) {
    self.onPressImage(@{@"index": @(index)});
  }
}

- (void)scrollToIndex:(NSInteger)index {
  NSInteger originalCount = self.data.count / 3;
  if (index < 0 || index >= originalCount) return;

  NSInteger targetIndex = index + originalCount;
  [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:targetIndex inSection:0]
                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                      animated:YES];
}

@end
