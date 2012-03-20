//
//  LabelViewFactory.m
//  PagingViewController
//
//  Created by Matthew Gillingham on 2/25/12.
//  Copyright (c) 2012 Matt Gillingham. All rights reserved.
//

#import "LabelViewFactory.h"
#import "PagingViewController.h"

@implementation LabelViewFactory

@synthesize array = _array;
@synthesize delegate = _delegate;

- (id)init {
  if ((self = [super init])) {
    _array = [[NSMutableArray alloc] initWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil];
  }
  return self;
}

- (void)dealloc {
  [_array release];
  [super dealloc];
}

- (UIView*)viewForIndex:(NSInteger)index {
  if (index != 0) {
    return nil;
  }

  UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 50.0f)];
  label.text = [self.array objectAtIndex:index];
  [view addSubview:label];
  [label release];
  
  UIButton *addButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [addButton setTitle:@"+" forState:UIControlStateNormal];
  [addButton addTarget:self action:@selector(addItem:) forControlEvents:UIControlEventTouchUpInside];
  addButton.frame = CGRectMake(
    view.frame.size.width / 2.0f - 50.0f,
    view.frame.size.height / 2.0f - 25.0f,
    100.0f,
    50.0f
  );
  [view addSubview:addButton];
  
  UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [deleteButton setTitle:@"-" forState:UIControlStateNormal];
  [deleteButton addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
  deleteButton.frame = CGRectMake(
    view.frame.size.width / 2.0f - 50.0f,
    view.frame.size.height / 2.0f + 25.0f,
    100.0f,
    50.0f
  );
  [view addSubview:deleteButton];
  
  view.backgroundColor = [UIColor blueColor];
  
  return [view autorelease];
}

- (UIView*)viewToInsertAtIndex:(NSInteger)index {
  return [self viewForIndex:index];
}

- (BOOL)canInsertViewAtIndex:(NSInteger)index {
  return YES;
}

- (BOOL)canDeleteViewAtIndex:(NSInteger)index {
  return YES;
}

- (void)willInsertViewAtIndex:(NSInteger)index {
  [_array insertObject:[NSString stringWithFormat:@"%da", index] atIndex:index];
}

- (void)willDeleteViewAtIndex:(NSInteger)index {
  [_array removeObjectAtIndex:index];
}

- (void)addItem:(id)sender {
  [self.delegate addView];
}

- (void)deleteItem:(id)sender {
  [self.delegate deleteView];
}

@end
