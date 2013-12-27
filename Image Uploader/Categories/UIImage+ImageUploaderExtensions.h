//
//  UIImage+fixOrientation.h
//  Image Uploader
//
//  Created by Adrian Adamkovic on 26/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: UIImage helpers

#import <UIKit/UIKit.h>

@interface UIImage (ImageUploaderExtensions)

+ (UIImage *)resizeImagePreservingAspectRatio:(UIImage *)orginalImage resizeSize:(CGSize)size;

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize;

@end
