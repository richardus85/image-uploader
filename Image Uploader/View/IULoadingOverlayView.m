//
//  IULoadingOverlayView.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 27/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Simple reusable view to indicate processing

#import "IULoadingOverlayView.h"

@implementation IULoadingOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (id)loadingView
{
    IULoadingOverlayView *loadingView = [[[NSBundle mainBundle] loadNibNamed:@"IULoadingOverlayView" owner:nil options:nil] lastObject];
    
    // make sure customView is not nil or the wrong class!
    if ([loadingView isKindOfClass:[IULoadingOverlayView class]])
        return loadingView;
    else
        return nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
