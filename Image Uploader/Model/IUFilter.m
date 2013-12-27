//
//  IUFilter.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Wrapper class for core image filters

#import "IUFilter.h"
#import "UIImage+ImageUploaderExtensions.h"

@interface IUFilter ()

@property (nonatomic, strong, readwrite) CIFilter *ciFilter;

@end

@implementation IUFilter

#pragma mark - Initializers

- (instancetype)initWithCIFilterName:(NSString *)filterName {
    
    if (self = [super init]) {
        
        self.ciFilter = [CIFilter filterWithName:filterName];
    };
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    
    IUFilter *filter = [[self class] allocWithZone:zone];
    
    filter->_ciFilter = [_ciFilter copyWithZone:zone];

    return filter;
}

- (id)init {
    
    return [self initWithCIFilterName:nil];
}

#pragma mark - Filter method

- (CIImage *)applyFilterToImage:(CIImage *)image {
    
    if (!image) {
        return nil;
    }
    
    [self.ciFilter setValue:image forKey:kCIInputImageKey];
    
    CIImage *result = [self.ciFilter valueForKey:kCIOutputImageKey];
    
    return result;
    
}

@end
