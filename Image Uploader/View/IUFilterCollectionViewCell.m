//
//  IUFilterCollectionViewCell.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Custom collection view cell for representing filter

#import "IUFilterCollectionViewCell.h"
#import "IUFilter.h"
#import "IUImage.h"
#import "UIImage+ImageUploaderExtensions.h"

@interface IUFilterCollectionViewCell ()

@property (nonatomic, strong, readwrite) IUFilter *filter;
@property (nonatomic, strong) IUImage *image;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) CIContext *ciContext;

@end

@implementation IUFilterCollectionViewCell

#pragma mark - Initializers

- (void)setActive:(BOOL)active {
    
    _active = active;
    
    if (active) {
      
        self.contentView.layer.borderWidth = 3.0f;
        self.contentView.layer.borderColor = [UIColor redColor].CGColor;
    }
    else {
       
        self.contentView.layer.borderWidth = 0.0f;
        self.contentView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        //Prepare global Core image context to reuse
        //Create a CIContext object from an EAGL context to avoid unnecessary texture transfers between the CPU and GPU.
        EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        //disable color management to boost performance
        NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null] };
        
        self.ciContext = [CIContext contextWithEAGLContext:myEAGLContext options:options];
        
        [self setupViews];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self setupViews];
    }
    return self;
}

#pragma mark - Helper methods

- (void)setupViews {
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    self.imageView.backgroundColor = [UIColor clearColor];
    //self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.contentView addSubview:self.imageView];
    
    //calculate title label height based on cell frame - reserve 30 percent
    CGFloat titleHeight = rintf(self.contentView.bounds.size.height*0.3f);
    
    UIView *transparentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.contentView.bounds.size.height - titleHeight, self.contentView.bounds.size.width, titleHeight)];
    transparentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    
    [self.contentView addSubview:transparentView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5.0f, transparentView.bounds.size.height - titleHeight, transparentView.bounds.size.width - 10.0f, titleHeight)];
    
    self.titleLabel.font = [UIFont systemFontOfSize:9.0f];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [transparentView addSubview:self.titleLabel];
}

- (void)setupCellWithFilter:(IUFilter *)filter andImage:(IUImage *)image {
    
    self.filter = filter;
    
    self.titleLabel.text = [self.filter.ciFilter.attributes objectForKey:kCIAttributeFilterDisplayName];;
    
    self.image = image;
    
    if (!image.thumbnailImage) {
        image.thumbnailImage = [UIImage resizeImage:image.originalImage newSize:self.imageView.bounds.size];
    }
    
    if (!self.image.imagePreviewsForFilters[self.filter.ciFilter.name]) {
       
        //based on Apple: "each thread must create its own CIFilter objects. Otherwise, your app could behave unexpectedly."
        IUFilter *filterForThread = [self.filter copy];
        
        dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(concurrentQueue, ^{
            
            IUFilter *filter = filterForThread;
            
            UIImageOrientation originalOrientation = self.image.imageReadyToProcess.imageOrientation;
            CGFloat originalScale = self.image.imageReadyToProcess.scale;
            
            CIImage *result = [filter applyFilterToImage:[CIImage imageWithCGImage:image.thumbnailImage.CGImage]];
            
            CGRect extent = [result extent];
            
            CGImageRef cgImage = [self.ciContext createCGImage:result fromRect:extent];
            
            UIImage *outputImage = [UIImage imageWithCGImage:cgImage scale:originalScale orientation:originalOrientation];
            
            CGImageRelease(cgImage);
            
            dispatch_async(dispatch_get_main_queue(), ^{
              
                image.imagePreviewsForFilters[filter.ciFilter.name] = outputImage;
                
                self.imageView.image = image.imagePreviewsForFilters[filter.ciFilter.name];
            });
            
        });
    }
    else {
        
        self.imageView.image = self.image.imagePreviewsForFilters[self.filter.ciFilter.name];
    }
}

- (void)prepareForReuse {
    
    self.titleLabel.text = nil;
    self.imageView.image = nil;
    self.active = NO;
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
