//
//  LabelViewFactory.h
//  PagingViewController
//
//  Created by Matthew Gillingham on 2/25/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PagingScrollView.h"

@protocol LabelFactoryDelegate <NSObject>

- (void)addView;
- (void)deleteView;

@end

@interface LabelViewFactory : NSObject <PagingScrollViewDelegate>

@property (nonatomic, retain) NSMutableArray *array;
@property (nonatomic, assign) id<LabelFactoryDelegate> delegate;

@end
