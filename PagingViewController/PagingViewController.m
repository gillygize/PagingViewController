//
//  ViewController.m
//  PagingViewController
//
//  Created by Matthew Gillingham on 2/25/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import "PagingViewController.h"

@implementation PagingViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nil bundle:nil])) {
    _factory = [[LabelViewFactory alloc] init];
    _factory.delegate = self;
  }
  
  return self;
}

- (void)dealloc {
  [_scrollView removeFromSuperview];
  [_scrollView release];
  
  [_factory release];
  
  [super dealloc];
}

- (void)loadView {
  self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
  _scrollView = [[PagingScrollView alloc] initWithFrame:self.view.bounds delegate:_factory];

  [self.view addSubview:_scrollView];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  _scrollView.frame = self.view.bounds;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return YES;
}

- (void)addView {
  [_scrollView insertViewAfterCurrentPage];
}

- (void)deleteView {
  [_scrollView deleteViewAtCurrentPage];
}

@end
