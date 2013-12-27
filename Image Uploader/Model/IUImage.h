//
//  IUImage.h
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Model class for representing image

#import <Foundation/Foundation.h>

typedef void (^callBackBlock)(UIImage *processedImage);

@interface IUImage : NSObject

@property (nonatomic, strong) NSMutableArray *filters;
@property (nonatomic, strong, readonly) UIImage *originalImage;
@property (nonatomic, strong) UIImage *imageReadyToProcess; //If needed scaled image ready to process
@property (nonatomic, strong) UIImage *processedImage; //Result image after all filters from "filters" array applied

@property (nonatomic, strong) UIImage *thumbnailImage;

@property (nonatomic, strong) NSMutableDictionary *imagePreviewsForFilters; //Prepared image previews with applied different filters

- (instancetype)initWithImage:(UIImage *)image;

@end
