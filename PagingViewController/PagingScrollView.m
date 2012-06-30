//
//  PagingScrollView.m
//  PagingViewController
//
//  Created by Matthew Gillingham on 3/3/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PagingScrollView.h"

@interface CBScrollView (FixedContentOffset)
@end

@implementation CBScrollView (FixedContentOffset)
- (void)setContentOffset:(CGPoint)contentOffset {
  if (!self.dragging && !self.decelerating) {
    id pagingView = self.superview;
    [super setContentOffset:CGPointMake(
      self.bounds.size.width * ((NSUInteger) [pagingView currentOffset] + (NSUInteger)[pagingView currentPageIndex]),
      0.0f
    )];
  } else {
    [super setContentOffset:contentOffset];
  }
}
@end

// The number of views to keep in memory.  Must be odd.
static const NSUInteger viewsCount = 3;

@interface PagingScrollView ()

@property (nonatomic, retain) NSMutableArray *views;
@property NSUInteger currentOffset;
@property NSUInteger currentPageIndex;
@property CGPoint startingContextOffset;
@property NSUInteger currentViewsCount;
@property BOOL shifting;

- (void)shiftLeft;
- (void)shiftRight;

@end

@implementation PagingScrollView

@synthesize scrollView = _scrollView;
@synthesize pageCount = _pageCount;
@synthesize currentOffset = _currentOffset;
@synthesize currentPageIndex = _currentPageIndex;
@synthesize currentView = _currentView;
@synthesize views = _views;
@synthesize currentViewsCount = _currentViewsCount;
@synthesize startingContextOffset = _startingContextOffset;
@synthesize shifting = _shifting;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount delegate:(id<PagingScrollViewDelegate>)delegate
{
  if ((self = [super initWithFrame:frame])) {
    _views = [[NSMutableArray alloc] initWithCapacity:viewsCount];
    _delegate = delegate;
    _shifting = NO;
      
    _currentPageIndex = 0;
    _currentOffset = 0;
    _pageCount = pageCount;
    
    for (NSUInteger i = _currentOffset; i < pageCount; i++) {
      UIView *view = [self.delegate pagingScrollView:self viewForIndex:i];    
      NSAssert(nil != view, @"The view cannot be nil");
      [self.views addObject:view];
    }
    
    [self jumpToPageAtIndex:_currentOffset+_currentPageIndex animated:NO completion:nil];
    
    [self update];
      
    self.backgroundColor = [UIColor whiteColor];
    
    [self addState:@"normal" enter:nil exit:nil];
  }

  return self;
}

- (void)dealloc {
  [_scrollView removeFromSuperview];
  [_scrollView release];
  
  [_views release];
  
  [super dealloc];
}

- (void)update {
  for (int i = 0; i < [self.views count]; i++) {
    UIView *view = [self.views objectAtIndex:i];
      
    view.frame = CGRectMake(
      self.scrollView.bounds.size.width * self.currentOffset + i * self.scrollView.bounds.size.width,
      0.0f,
      self.scrollView.bounds.size.width,
      self.scrollView.bounds.size.height
    );
            
    if (nil == view.superview) {
      [self.scrollView addSubview:view];
    }
  }
   
  [self.scrollView setContentOffset:CGPointMake(
    self.scrollView.bounds.size.width * (self.currentOffset + self.currentPageIndex),
    0.0f
  ) animated:NO];
  
  NSLog(@"Update: %@ %@ %@ %d %d %d", self.views, NSStringFromCGPoint(self.scrollView.contentOffset), NSStringFromCGSize(self.scrollView.contentSize), self.pageCount, self.currentOffset, self.currentPageIndex);
}

#pragma mark - Public Interface
- (void)insertViewBeforeCurrentPageAnimated:(BOOL)animated completion:(void (^)(void))completion {
  if (![self.delegate respondsToSelector:@selector(pagingScrollView:canInsertViewAtIndex:)] ||
      ![self.delegate pagingScrollView:self canInsertViewAtIndex:self.currentOffset+self.currentPageIndex]) {
    return;
  }
  
  if ([self.delegate respondsToSelector:@selector(pagingScrollView:willInsertViewAtIndex:)]) {
    [self.delegate pagingScrollView:self willInsertViewAtIndex:self.currentOffset+self.currentPageIndex];
  }
  
  self.pageCount += 1;
  
  [self jumpToPageAtIndex:self.currentOffset+self.currentPageIndex animated:NO completion:nil];
  
  NSUInteger insertionIndex;
  
  if (self.currentOffset + self.currentPageIndex < viewsCount / 2) {
    insertionIndex = self.currentOffset + self.currentPageIndex;
  } else if (self.currentOffset + self.currentPageIndex >= self.pageCount - viewsCount / 2) {
    insertionIndex = self.pageCount - self.currentOffset + self.currentPageIndex;
  } else {
    insertionIndex = viewsCount / 2;
  }
  
  UIView *viewToInsert = [self.delegate pagingScrollView:self viewToInsertAtIndex:self.currentOffset + insertionIndex];

  viewToInsert.alpha = 0.0f;
  viewToInsert.frame = CGRectMake(
    self.scrollView.bounds.size.width * self.currentOffset + insertionIndex * self.scrollView.bounds.size.width,
    0.0f,
    self.scrollView.bounds.size.width,
    self.scrollView.bounds.size.height
  );
  
  [self.scrollView addSubview:viewToInsert];
  
  void (^animationBlock)() = ^{
    for (int i = insertionIndex; i < [self.views count]; i++) {
      id object = [self.views objectAtIndex:i];
      
      if ([object isKindOfClass:[UIView class]]) {
        UIView *currentView = (UIView*)object;
        
        currentView.frame = CGRectMake(
          self.scrollView.bounds.size.width * self.currentOffset + (i + 1) * self.scrollView.bounds.size.width,
          0.0f,
          self.scrollView.bounds.size.width,
          self.scrollView.bounds.size.height
        );
      }
    }
  };
  
  void (^completionBlock)(BOOL) = ^(BOOL finished) {
    [UIView animateWithDuration:0.3f
      animations:^{
        viewToInsert.alpha = 1.0f;
      }
      completion:^(BOOL finished){
        [self.views insertObject:viewToInsert atIndex:insertionIndex];
          
        if (self.views.count == viewsCount) {
          UIView *lastItem = [self.views lastObject];
          [lastItem removeFromSuperview];
          [self.views removeLastObject];
        }
        
        self.currentPageIndex = insertionIndex;
        self.currentView = [self.views objectAtIndex:insertionIndex];
                    
        if ([self.delegate respondsToSelector:@selector(pagingScrollView:didInsertViewAtIndex:)]) {
          [self.delegate pagingScrollView:self didInsertViewAtIndex:self.currentOffset+self.currentPageIndex];
        }
        
        if (completion) {
          completion();
        }
      }
    ];
  };
  
  if (animated) {
    [UIView animateWithDuration:0.3f animations:animationBlock completion:completionBlock];
  } else {
    animationBlock();
    completionBlock(YES);
  }
}

- (void)insertViewAfterCurrentPageAnimated:(BOOL)animated completion:(void (^)(void))completion {
  if (![self.delegate respondsToSelector:@selector(pagingScrollView:canInsertViewAtIndex:)] ||
      ![self.delegate pagingScrollView:self canInsertViewAtIndex:self.currentOffset+self.currentPageIndex+1]) {
    return;
  }
  
  if ([self.delegate respondsToSelector:@selector(pagingScrollView:willInsertViewAtIndex:)]) {
    [self.delegate pagingScrollView:self willInsertViewAtIndex:self.currentOffset+self.currentPageIndex+1];
  }
  
  self.pageCount += 1;
      
  UIView *viewToInsert = [self.delegate pagingScrollView:self viewToInsertAtIndex:self.currentOffset+self.currentPageIndex];
  [self.views insertObject:viewToInsert atIndex:self.currentPageIndex];

  [self jumpToPageAtIndex:self.currentOffset+self.currentPageIndex animated:NO completion:nil];
  [self shiftRight];
  
  if ([self.delegate respondsToSelector:@selector(pagingScrollView:didInsertViewAtIndex:)]) {
    [self.delegate pagingScrollView:self didInsertViewAtIndex:self.currentOffset+self.currentPageIndex];
  }
}

//- (void)deleteViewAtCurrentPageAnimated:(BOOL)animated completion:(void (^)(void))completion {
//  if (![self.delegate respondsToSelector:@selector(pagingScrollView:canDeleteViewAtIndex:)] ||
//      ![self.delegate pagingScrollView:self canDeleteViewAtIndex:self.currentPage]) {
//    return;
//  }
//  
//  if ([self.delegate respondsToSelector:@selector(pagingScrollView:willDeleteViewAtIndex:)]) {
//    [self.delegate pagingScrollView:self willDeleteViewAtIndex:self.currentPage];
//  }
//    
//  void (^animationBlock)() = ^{
//    self.currentView.alpha = 0.0f;
//  };
//  
//  void (^completionBlock)(BOOL) = ^(BOOL finished) {
//    [self.currentView removeFromSuperview];
//
//    [UIView animateWithDuration:0.3f
//      animations:^{
//        for (int i = _centerIndex+1; i <= viewsCount; i++) {      
//          UIView *currentView = (UIView*) [self.views objectAtIndex:i];
//        
//          currentView.frame = CGRectMake(
//            currentView.frame.origin.x - self.scrollView.bounds.size.width,
//            currentView.frame.origin.y,
//            currentView.frame.size.width,
//            currentView.frame.size.height
//          );
//        }
//      }
//      
//      completion:^(BOOL finished) {
//        [self.views removeObjectAtIndex:self.centerIndex];
//        self.currentView = [self.views objectAtIndex:self.centerIndex];
//        
//        // If we just deleted the last view on the list (ie. the view self.centerIndex is NSNull) jump backwards
//        // one view.
//        UIView *newCenterView = [self.views objectAtIndex:self.centerIndex];
//        if ([newCenterView isKindOfClass:[NSNull class]]) {
//          [self moveBackwardsOnePageAnimated:YES completion:^{
//            if ([self.delegate respondsToSelector:@selector(pagingScrollView:didDeleteViewAtIndex:)]) {
//              [self.delegate pagingScrollView:self didDeleteViewAtIndex:self.currentPage];
//            }
//            
//            self.pageCount -= 1;
//  
//            self.scrollView.contentSize = CGSizeMake(
//            self.scrollView.bounds.size.width * self.pageCount,
//            self.scrollView.bounds.size.height 
//  );
//          }];
//        }
//      }
//    ];
//  };
//
//  if (animated) {
//    [UIView animateWithDuration:0.3f animations:animationBlock completion:completionBlock];
//  } else {
//    animationBlock();
//    completionBlock(YES);
//  }
//}

#pragma mark - Internal Methods
- (void)shiftLeft {
  self.currentPageIndex -= 1;

  if ((self.currentOffset + self.currentPageIndex < viewsCount / 2) || self.views.count < viewsCount || (self.currentOffset + self.currentPageIndex > self.pageCount - viewsCount / 2)) {
    return;
  }
  
  UIView *view = [self.views lastObject];
  [view removeFromSuperview];
  [self.views removeLastObject];
  
  view = [self.delegate pagingScrollView:self viewForIndex:self.currentOffset-1];
  view.frame = self.scrollView.bounds;
  
  self.currentOffset -= 1;
  self.currentPageIndex += 1;
  
  [self.views insertObject:view atIndex:0];
  [self.scrollView addSubview:view];
  [self update];
}

- (void)shiftRight {
  self.currentPageIndex += 1;
  
  if ((self.currentOffset + self.currentPageIndex < viewsCount / 2) || self.views.count < viewsCount || (self.currentOffset + self.currentPageIndex > self.pageCount - viewsCount / 2)) {
    return;
  }
    
  UIView *view = [self.views objectAtIndex:0];
  [view removeFromSuperview];
  [self.views removeObjectAtIndex:0];
  
  view = [self.delegate pagingScrollView:self viewForIndex:self.currentOffset+viewsCount-1];
  view.frame = self.scrollView.bounds;
  
  self.currentOffset += 1;
  self.currentPageIndex -= 1;
  
  [self.views addObject:view];
  [self.scrollView addSubview:view];
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)(void))completion {
  self.scrollView = nil;

  CBScrollView *scrollView = [[CBScrollView alloc] initWithFrame:self.bounds];
  scrollView.backgroundColor = [UIColor redColor];
  scrollView.pagingEnabled = YES;
  scrollView.scrollEnabled = YES;
  scrollView.delegate = self;
  scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  scrollView.showsHorizontalScrollIndicator = YES;
  scrollView.contentSize = CGSizeMake(
    scrollView.bounds.size.width * self.pageCount,
    scrollView.bounds.size.height
  );
  
  [scrollView addState:@"normal" enter:nil exit:nil];
  
  [self addSubview:scrollView];
  self.scrollView = scrollView;
  
  [scrollView release];
  
  NSUInteger startIndex;
  NSUInteger endIndex;
  
  if (index < viewsCount / 2) {
    startIndex = 0;
    endIndex = startIndex + [self.views count];
  } else if (index + viewsCount > self.pageCount) {
    startIndex = self.pageCount - viewsCount;
    endIndex = self.pageCount;
  } else {
    startIndex = index - viewsCount / 2;
    endIndex = startIndex + viewsCount;
  }
    
  [self.views removeAllObjects];
  [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
  
  for (NSUInteger i = startIndex; i < endIndex; i++) {
    UIView *view = [self.delegate pagingScrollView:self viewForIndex:i];    
    NSAssert(nil != view, @"The view cannot be nil");
    [self.views addObject:view];
  }
  
  self.currentOffset = startIndex;
  self.currentPageIndex = index - startIndex;
  self.currentView = self.views.count > 0 ? [self.views objectAtIndex:self.currentPageIndex] : nil;
  [self update];
}

- (void)moveForwardOnePageAnimated:(BOOL)animated completion:(void(^)(void))completion {  
  void(^animations)() = ^{
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width * self.currentOffset+self.currentPageIndex+1, 0.0f) animated:YES];
  };
  
  void(^thisCompletion)(BOOL) = ^(BOOL finished){
    [self shiftRight];
    
    if (completion) {
      completion();
    }
  };
  
  if (animated) {
    [UIView animateWithDuration:0.3f animations:animations completion:thisCompletion];
  } else {
    animations();
    thisCompletion(YES);
  }
}

- (void)moveBackwardsOnePageAnimated:(BOOL)animated completion:(void(^)(void))completion {
  if (self.currentOffset + self.currentPageIndex == 0) {
    return;
  }

  void(^animations)() = ^{  
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width * self.currentOffset+self.currentPageIndex+1,0.0f) animated:NO];
  };
  
  void(^thisCompletion)(BOOL finished) = ^(BOOL finished){
    [self shiftLeft];
    
    if (completion) {
      completion();
    }
  };
  
  if (animated) {
    [UIView animateWithDuration:0.3f animations:animations completion:thisCompletion];
  } else {
    animations();
    thisCompletion(YES);
  }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  self.startingContextOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (decelerate) {
    return;
  }

  [self updateScrollViewPosition:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {  
  [self updateScrollViewPosition:scrollView];
}

- (void)updateScrollViewPosition:(UIScrollView*)scrollView {
  CGFloat widthPerElement = scrollView.bounds.size.width;
  
  NSInteger startingPosition = (NSInteger)floor(self.startingContextOffset.x / widthPerElement);
  NSInteger endingPosition = (NSInteger)floor(scrollView.contentOffset.x / widthPerElement);
  
  if (endingPosition > startingPosition) {
    for (int i = 0; i < endingPosition - startingPosition; i++) {
      [self shiftRight];
    }
  } else if (endingPosition < startingPosition) {
    for (int i = 0; i < startingPosition - endingPosition; i++) {
      [self shiftLeft];
    }
  }
}



@end