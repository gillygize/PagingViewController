//
//  ViewController.h
//  PagingViewController
//
//  Created by Matthew Gillingham on 2/25/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagingScrollView.h"
#import "LabelViewFactory.h"

@interface PagingViewController : UIViewController <LabelFactoryDelegate> {
  PagingScrollView *_scrollView;
  LabelViewFactory *_factory;
}

@end
