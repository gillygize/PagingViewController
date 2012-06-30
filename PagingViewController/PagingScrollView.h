//
//  PagingScrollView.h
//  PagingViewController
//
//  Created by Matthew Gillingham on 3/3/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CBView.h"

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

@end

@interface PagingScrollView : CBView <UIScrollViewDelegate>

@property (nonatomic, retain) CBScrollView *scrollView;
@property (nonatomic, assign) UIView *currentView;
@property NSUInteger pageCount;
@property (nonatomic, assign) id<PagingScrollViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount delegate:(id<PagingScrollViewDelegate>)delegate;

- (void)insertViewBeforeCurrentPageAnimated:(BOOL)animated completion:(void(^)(void))completion;
- (void)insertViewAfterCurrentPageAnimated:(BOOL)animated completion:(void(^)(void))completion;
- (void)deleteViewAtCurrentPageAnimated:(BOOL)animated completion:(void(^)(void))completion;

- (void)moveForwardOnePageAnimated:(BOOL)animated completion:(void(^)(void))completion;
- (void)moveBackwardsOnePageAnimated:(BOOL)animated completion:(void(^)(void))completion;
- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)(void))completion;
@end
