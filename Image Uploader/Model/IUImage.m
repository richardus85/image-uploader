//
//  IUImage.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Model class for representing image

#import "IUImage.h"
#import "IUFilter.h"

@interface IUImage ()

@property (nonatomic, strong, readwrite) UIImage *originalImage;

@end

@implementation IUImage

#pragma mark - Initializers

- (id)init {
    
    return [self initWithImage:nil];
}

- (instancetype)initWithImage:(UIImage *)image {
    
    if (self = [super init]) {
        
        self.imagePreviewsForFilters = [NSMutableDictionary dictionary];
        self.filters = [NSMutableArray array];
        
        self.originalImage = image;
        self.processedImage = image;
    }
    
    return self;
}

@end
