//
//  PagingScrollView.m
//  PagingViewController
//
//  Created by Matthew Gillingham on 3/3/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PagingScrollView.h"

static const NSUInteger viewsCount = 5;

@interface PagingScrollView ()

@property (nonatomic, retain) NSMutableArray *views;
@property NSUInteger centerIndex;
@property CGPoint startingContextOffset;
@property NSUInteger currentViewsCount;
@property BOOL shifting;

- (void)shift:(NSInteger)shiftAmount;
- (NSIndexSet*)validViewIndexes;

@end

@implementation PagingScrollView

@synthesize scrollView = _scrollView;
@synthesize currentPage = _currentPage;
@synthesize currentView = _currentView;
@synthesize views = _views;
@synthesize centerIndex = _centerIndex;
@synthesize currentViewsCount = _currentViewsCount;
@synthesize startingContextOffset = _startingContextOffset;
@synthesize shifting = _shifting;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame delegate:(id<PagingScrollViewDelegate>)delegate
{
  if ((self = [super initWithFrame:frame])) {
    _views = [[NSMutableArray alloc] initWithCapacity:viewsCount];
    _centerIndex = viewsCount / 2;
    _delegate = delegate;
      
    _currentPage = 0;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:_scrollView];
    
    [self jumpToPageAtIndex:_currentPage animated:NO];
      
    self.backgroundColor = [UIColor whiteColor];
  }

  return self;
}

- (void)dealloc {
  [_scrollView removeFromSuperview];
  [_scrollView release];
  
  [_views release];
  
  [super dealloc];
}

- (void)layoutSubviews {
  [self update];
}

- (void)update {
  NSIndexSet *viewIndexes = [self validViewIndexes];
  
  if ([viewIndexes count] < 1) {
    return;
  }
  
  self.currentViewsCount = [viewIndexes count];

  for (int i = [viewIndexes firstIndex]; i <= [viewIndexes lastIndex]; i++) {
    UIView *view = [self.views objectAtIndex:i];
    view.bounds = CGRectMake(
      0.0f,
      0.0f,
      self.scrollView.bounds.size.width,
      self.scrollView.bounds.size.height
    );
    view.center = CGPointMake(
      self.scrollView.bounds.size.width / 2.0f + self.scrollView.bounds.size.width * (i - [viewIndexes firstIndex]),
      self.scrollView.bounds.size.height / 2.0f 
    );
            
    if (nil == view.superview) {
      [self.scrollView addSubview:view];
    }
  }

  self.scrollView.contentSize = CGSizeMake(
    self.scrollView.bounds.size.width * self.currentViewsCount,
    self.scrollView.bounds.size.height
  );
  
  self.scrollView.contentOffset = CGPointMake(
    self.scrollView.bounds.size.width * (_centerIndex - [[self validViewIndexes] firstIndex]),
    0.0f
  );  
}

#pragma mark - Public Interface

// Deletes the current view.  The contact for this method stipulates that, while the
// self.views array can be manipulated during its execution, by the time this method
// is finished, the array will be back to its normal operation.
- (void)insertViewBeforeCurrentPage {
  if (![self.delegate respondsToSelector:@selector(canInsertViewAtIndex:)] ||
      ![self.delegate canInsertViewAtIndex:self.currentPage]) {
    return;
  }
  
  if ([self.delegate respondsToSelector:@selector(willInsertViewAtIndex:)]) {
    [self.delegate willInsertViewAtIndex:self.currentPage];
  }
  
  UIView *viewToInsert = [self.delegate viewToInsertAtIndex:self.currentPage];
  
  viewToInsert.alpha = 0.0f;
  viewToInsert.frame = CGRectMake(
    self.scrollView.bounds.size.width * (_centerIndex - [[self validViewIndexes] firstIndex]),
    0.0f,
    self.scrollView.bounds.size.width,
    self.scrollView.bounds.size.height
  );
  
  [self.scrollView addSubview:viewToInsert];
  
  [UIView animateWithDuration:0.3f
    animations:^{
      for (int i = _centerIndex; i < viewsCount; i++) {
        id object = [self.views objectAtIndex:i];
      
        if ([object isKindOfClass:[UIView class]]) {
          UIView *currentView = (UIView*)object;
        
          currentView.frame = CGRectMake(
            currentView.frame.origin.x + self.scrollView.bounds.size.width,
            currentView.frame.origin.y,
            currentView.frame.size.width,
            currentView.frame.size.height
          );
        }
      }
    }
    completion:^(BOOL finished){
      [UIView animateWithDuration:0.3f
        animations:^{
          viewToInsert.alpha = 1.0f;
        }
        completion:^(BOOL finished){
          id lastItem = [self.views objectAtIndex:viewsCount-1];
  
          if ([lastItem isKindOfClass:[UIView class]]) {
            [lastItem removeFromSuperview];
          }

          [self.views removeObjectAtIndex:viewsCount-1];
          [self.views insertObject:viewToInsert atIndex:self.centerIndex];
          
          self.currentView = [self.views objectAtIndex:self.centerIndex];

          if (_centerIndex == [[self validViewIndexes] lastIndex]) {
            [self setNeedsLayout];
          }
      
          if ([self.delegate respondsToSelector:@selector(didInsertViewAtIndex:)]) {
            [self.delegate didInsertViewAtIndex:self.currentPage];
          }
        }
      ];
    }];  
}

- (void)insertViewAfterCurrentPage {
  [self moveForwardOnePage:YES];
  
  double delayInSeconds = 0.6;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self insertViewBeforeCurrentPage];
  });
}

// Deletes the current view.  The contact for this method stipulates that, while the
// self.views array can be manipulated during its execution, by the time this method
// is finished, the array will be back to its normal operation.
- (void)deleteViewAtCurrentPage {
  if (![self.delegate respondsToSelector:@selector(canDeleteViewAtIndex:)] ||
      ![self.delegate canDeleteViewAtIndex:self.currentPage]) {
    return;
  }
  
  if ([self.delegate respondsToSelector:@selector(willDeleteViewAtIndex:)]) {
    [self.delegate willDeleteViewAtIndex:self.currentPage];
  }

  UIView *centerView = [self.views objectAtIndex:_centerIndex];
  id lastItem = [self.delegate viewForIndex:self.currentPage+_centerIndex];
    
  if (nil == lastItem || [[self validViewIndexes] lastIndex] != viewsCount - 1) {
    lastItem = [NSNull null];
  } else {
    UIView *lastView = (UIView*)lastItem;
    UIView *currentLastView = [self.views objectAtIndex:viewsCount-1];
    lastView.frame = CGRectMake(
      currentLastView.frame.origin.x + self.scrollView.bounds.size.width,
      0.0f,
      currentLastView.frame.size.width,
      currentLastView.frame.size.height
    );
    [self.scrollView addSubview:lastView];
  }
  
  [UIView animateWithDuration:0.3f animations:^{
    centerView.alpha = 0.0f;
  } completion:^(BOOL finished){
    [centerView removeFromSuperview];
    [self.views addObject:lastItem];

    [UIView animateWithDuration:0.3f
      animations:^{
        for (int i = _centerIndex+1; i <= viewsCount; i++) {
          id object = [self.views objectAtIndex:i];
      
          if ([object isKindOfClass:[UIView class]]) {
            UIView *currentView = (UIView*)object;
        
            currentView.frame = CGRectMake(
              currentView.frame.origin.x - self.scrollView.bounds.size.width,
              currentView.frame.origin.y,
              currentView.frame.size.width,
              currentView.frame.size.height
            );
          }
        }
      }
      
      completion:^(BOOL finished) {
        [self.views removeObjectAtIndex:self.centerIndex];
        self.currentView = [self.views objectAtIndex:self.centerIndex];
        
        // If we just deleted the last view on the list (ie. the view self.centerIndex is NSNull) jump backwards
        // one view.
        UIView *newCenterView = [self.views objectAtIndex:self.centerIndex];
        if ([newCenterView isKindOfClass:[NSNull class]]) {
          [self moveBackwardsOnePage:YES];
        }
        
        if ([self.delegate respondsToSelector:@selector(didDeleteViewAtIndex:)]) {
          [self.delegate didDeleteViewAtIndex:self.currentPage];
        }
      }];
  }];
}

#pragma mark - Internal Methods
- (void)shift:(NSInteger)shiftAmount {
  NSAssert(abs(shiftAmount) <= viewsCount / 2, @"The shift was greater than half of the array");
  
  if (shiftAmount != 0 && [self.delegate respondsToSelector:@selector(willChangeCurrentPageFromIndex:toIndex:)]) {
    [self.delegate willChangeCurrentPageFromIndex:self.currentPage toIndex:self.currentPage+shiftAmount];
  }
  
  if (shiftAmount > 0) {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, shiftAmount)];

    for (int i = [indexSet firstIndex]; i <= [indexSet lastIndex]; i++) {
      id obj = [self.views objectAtIndex:i];
      
      if (![obj isKindOfClass:[UIView class]]) {
        continue;
      }
    
      UIView *view = (UIView*)obj;
      
      [view removeFromSuperview];
    }
    
    [self.views removeObjectsAtIndexes:indexSet];
    
    BOOL insertNull = NO;
    
    for (int i = 1; i <= shiftAmount; i++) {
      id view = [self.delegate viewForIndex:self.currentPage + viewsCount / 2 + i];
      
      if (insertNull || (nil == view)) {
        view = [NSNull null];
        insertNull = YES;
      }
      
      [self.views addObject:view];
    }
  } else if (shiftAmount < 0) {
    NSUInteger positiveShiftAmount = abs(shiftAmount);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(
      viewsCount - positiveShiftAmount,
      positiveShiftAmount
    )];

    for (int i = [indexSet firstIndex]; i <= [indexSet lastIndex]; i++) {
      id obj = [self.views objectAtIndex:i];

      if (![obj isKindOfClass:[UIView class]]) {
        continue;
      }
    
      UIView *view = (UIView*)obj;
      
      [view removeFromSuperview];
    }
    
    [self.views removeObjectsAtIndexes:indexSet];
    
    BOOL insertNull = NO;
    
    for (int i = 1; i <= positiveShiftAmount; i++) {
      id view = [self.delegate viewForIndex:self.currentPage - viewsCount / 2 - i];
      
      if (insertNull || (nil == view)) {
        view = [NSNull null];
        insertNull = YES;
      }
      
      [self.views insertObject:view atIndex:0];
    }
  }
  
  self.currentPage += shiftAmount;
  self.currentView = [self.views objectAtIndex:self.centerIndex];
  
  if (shiftAmount != 0 && [self.delegate respondsToSelector:@selector(didChangeCurrentPageFromIndex:toIndex:)]) {
    [self.delegate didChangeCurrentPageFromIndex:self.currentPage-shiftAmount toIndex:self.currentPage];
  }
}

- (void)jumpToPageAtIndex:(NSInteger)index animated:(BOOL)animated {
  BOOL leftIsNil = NO;
  BOOL rightIsNil = NO;
  NSInteger offset = index - viewsCount / 2;
  
  [self.views removeAllObjects];
  [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
      
  // This loads the view in the sequence count/2, count/2 + 1, count/2 - 1, etc...
  // aka. 2, 3, 1, 4, 0, 5
  // except the offset makes it 0, 1, -1, 2, -2
  for (NSInteger i = 0; i <= viewsCount / 2; i++) {
    NSInteger leftPosition = viewsCount / 2 - i + offset;
    NSInteger rightPosition = viewsCount / 2 + 1 + i + offset;
                
    UIView *leftView = [self.delegate viewForIndex:leftPosition];
          
    if (leftIsNil || (nil == leftView)) {
      [self.views insertObject:[NSNull null] atIndex:0];
      leftIsNil = YES;
    } else {
      [self.views insertObject:leftView atIndex:0];
    }
                
    if ((i != viewsCount / 2)) {
      UIView *rightView = [_delegate viewForIndex:rightPosition];
          
      if (rightIsNil || (nil == rightView)) {
        [self.views addObject:[NSNull null]];
        rightIsNil = YES;
      } else {
        [self.views addObject:rightView];
      }          
    }
  }
  
  self.currentPage = index;
  self.currentView = [self.views objectAtIndex:self.centerIndex];
  [self setNeedsLayout];
}

- (void)performSelectorOnViews:(SEL)selector withObject:(id)object {
  [self.views enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop){
    if ([obj respondsToSelector:selector]) {
      [obj performSelector:selector withObject:object];
    }
  }];
}

- (void)moveForwardOnePage:(BOOL)animated {
  CGFloat widthPerElement = self.scrollView.contentSize.width / self.currentViewsCount;
  
  void(^animations)() = ^{
    self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x + widthPerElement, 0.0f);
  };
  
  void(^completion)(BOOL finished) = ^(BOOL finished){
    [self shift:1];
    [self setNeedsLayout];
  };
  
  if (animated) {
    [UIView animateWithDuration:0.3f animations:animations completion:completion];
  } else {
    animations();
    completion(YES);
  }
}

- (void)moveBackwardsOnePage:(BOOL)animated {
  CGFloat widthPerElement = self.scrollView.contentSize.width / self.currentViewsCount;
  
  void(^animations)() = ^{
    self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x - widthPerElement, 0.0f);
  };
  
  void(^completion)(BOOL finished) = ^(BOOL finished){
    [self shift:-1];
    [self setNeedsLayout];
  };
  
  if (animated) {
    [UIView animateWithDuration:0.3f animations:animations completion:completion];
  } else {
    animations();
    completion(YES);
  }
}

- (NSIndexSet*)validViewIndexes {
  return [self.views indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
    return [obj isKindOfClass:[UIView class]];
  }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  if (!self.shifting) {
    self.shifting = YES;
    self.startingContextOffset = scrollView.contentOffset;
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {  
  CGFloat widthPerElement = scrollView.contentSize.width / self.currentViewsCount;
  
  NSInteger startingPosition = (NSInteger)floor(self.startingContextOffset.x / widthPerElement);
  NSInteger endingPosition = (NSInteger)floor(scrollView.contentOffset.x / widthPerElement);
  
  if (endingPosition != startingPosition) {
    [self shift:endingPosition - startingPosition];
    [self update];
 
    self.shifting = NO;
  }
}



@end
