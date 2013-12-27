//
//  IUFiltersViewController.h
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Collection view controller to display filter options

#import <UIKit/UIKit.h>

@class IUFiltersViewController;

@protocol IUFiltersControllerDelegate <NSObject>

@optional
- (void)filtersControllerDidApplyFilters:(IUFiltersViewController *)controller;
- (void)filtersControllerWillStartToApplyFilters:(IUFiltersViewController *)controller;

@end

@class IUImage;

@interface IUFiltersViewController : UICollectionViewController

@property (nonatomic, strong) IUImage *image;

@property (nonatomic, weak) id<IUFiltersControllerDelegate>delegate;

@property (nonatomic, strong, readonly) UIImage *filterImagePreview;
@property (nonatomic, strong, readonly) NSMutableArray *appliedFiltersArray;
@property (nonatomic, strong, readonly) CIContext *ciContext;

@end
