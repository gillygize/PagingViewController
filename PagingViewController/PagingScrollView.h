//
//  PagingScrollView.h
//  PagingViewController
//
//  Created by Matthew Gillingham on 3/3/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PagingScrollView;

@protocol PagingScrollViewDelegate <NSObject>

- (UIView*)pagingScrollView:(PagingScrollView*)pagingScrollView viewForIndex:(NSInteger)index;

@optional
- (BOOL)pagingScrollView:(PagingScrollView*)pagingScrollView canInsertViewAtIndex:(NSInteger)index;
- (BOOL)pagingScrollView:(PagingScrollView*)pagingScrollView canDeleteViewAtIndex:(NSInteger)index;

- (UIView*)pagingScrollView:(PagingScrollView*)pagingScrollView viewToInsertAtIndex:(NSInteger)index;

- (void)pagingScrollView:(PagingScrollView*)pagingScrollView willInsertViewAtIndex:(NSInteger)index;
- (void)pagingScrollView:(PagingScrollView*)pagingScrollView didInsertViewAtIndex:(NSInteger)index;

- (void)pagingScrollView:(PagingScrollView*)pagingScrollView willDeleteViewAtIndex:(NSInteger)index;
- (void)pagingScrollView:(PagingScrollView*)pagingScrollView didDeleteViewAtIndex:(NSInteger)index;

- (void)pagingScrollView:(PagingScrollView*)pagingScrollView willChangeCurrentPageFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)pagingScrollView:(PagingScrollView*)pagingScrollView didChangeCurrentPageFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIsndex;
@end

@interface PagingScrollView : UIView <UIScrollViewDelegate>

@property (nonatomic, retain) UIScrollView *scrollView;
@property NSInteger currentPage;
@property (nonatomic, assign) UIView *currentView;

@property (nonatomic, assign) id<PagingScrollViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame delegate:(id<PagingScrollViewDelegate>)delegate;

- (void)insertViewBeforeCurrentPage;
- (void)insertViewAfterCurrentPage;
- (void)deleteViewAtCurrentPage;

- (void)moveForwardOnePage:(BOOL)animated completion:(void(^)(void))completion;
- (void)moveBackwardsOnePage:(BOOL)animated completion:(void(^)(void))completion;
- (void)jumpToPageAtIndex:(NSInteger)index animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)performSelectorOnViews:(SEL)selector withObject:(id)object;
@end
