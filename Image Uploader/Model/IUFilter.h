//
//  IUFilter.h
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Wrapper class for core image filters

#import <Foundation/Foundation.h>

@interface IUFilter : NSObject

@property (nonatomic, strong, readonly) CIFilter *ciFilter;

- (instancetype)initWithCIFilterName:(NSString *)filterName;

- (CIImage *)applyFilterToImage:(CIImage *)image;

@end
