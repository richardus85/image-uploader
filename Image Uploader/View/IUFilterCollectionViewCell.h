//
//  IUFilterCollectionViewCell.h
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Custom collection view cell for representing filter

#import <UIKit/UIKit.h>

@class IUFilter, IUImage;

@interface IUFilterCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong, readonly) IUFilter *filter;
@property (nonatomic, assign, getter = isActive) BOOL active; //indicates if filter is activated

- (void)setupCellWithFilter:(IUFilter *)filter andImage:(IUImage *)image;

@end
