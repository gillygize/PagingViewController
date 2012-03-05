//
//  PagingScrollView.h
//  PagingViewController
//
//  Created by Matthew Gillingham on 3/3/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PagingScrollViewDelegate <NSObject>
- (UIView*)viewForIndex:(NSInteger)index;

@optional
- (BOOL)canInsertViewAtIndex:(NSInteger)index;
- (BOOL)canDeleteViewAtIndex:(NSInteger)index;

- (UIView*)viewToInsertAtIndex:(NSInteger)index;

- (void)willInsertViewAtIndex:(NSInteger)index;
- (void)didInsertViewAtIndex:(NSInteger)index;

- (void)willDeleteViewAtIndex:(NSInteger)index;
- (void)didDeleteViewAtIndex:(NSInteger)index;
@end

@interface PagingScrollView : UIView <UIScrollViewDelegate>

@property (nonatomic, retain) UIScrollView *scrollView;
@property NSInteger currentPage;

@property (nonatomic, assign) id<PagingScrollViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame delegate:(id<PagingScrollViewDelegate>)delegate;

- (void)insertViewBeforeCurrentPage;
- (void)deleteViewAtCurrentPage;

@end
