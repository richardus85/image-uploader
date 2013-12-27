//
//  UIImage+fixOrientation.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 26/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: UIImage helpers

#import "UIImage+ImageUploaderExtensions.h"

@implementation UIImage (ImageUploaderExtensions)

+ (UIImage *)resizeImagePreservingAspectRatio:(UIImage *)orginalImage resizeSize:(CGSize)size
{
	CGFloat actualHeight = orginalImage.size.height;
	CGFloat actualWidth = orginalImage.size.width;
	if(actualWidth <= size.width && actualHeight<=size.height)
	{
		return orginalImage;
	}
	float oldRatio = actualWidth/actualHeight;
	float newRatio = size.width/size.height;
	if(oldRatio < newRatio)
	{
		oldRatio = size.height/actualHeight;
		actualWidth = oldRatio * actualWidth;
		actualHeight = size.height;
	}
	else
	{
		oldRatio = size.width/actualWidth;
		actualHeight = oldRatio * actualHeight;
		actualWidth = size.width;
	}
	CGRect rect = CGRectMake(0.0,0.0,actualWidth,actualHeight);
	UIGraphicsBeginImageContext(rect.size);
	[orginalImage drawInRect:rect];
	orginalImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return orginalImage;
}

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    
    //UIImage *imageToProcess = [image fixOrientation];
    UIImageOrientation originalOrientation = image.imageOrientation;
    CGFloat originalScale = image.scale;
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:originalScale orientation:originalOrientation];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
