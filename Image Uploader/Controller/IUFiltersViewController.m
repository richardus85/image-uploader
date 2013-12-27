//
//  IUFiltersViewController.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Collection view controller to display filter options

#import "IUFiltersViewController.h"
#import "IUFilterCollectionViewCell.h"
#import "IUFilter.h"
#import "IUImage.h"
#import "UIImage+ImageUploaderExtensions.h"
#import "IUImageViewController.h"

@interface IUFiltersViewController ()

@property (nonatomic, strong) NSArray *filtersArray;
@property (nonatomic, strong, readwrite) NSMutableArray *appliedFiltersArray;

@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, strong, readwrite) UIImage *filterImagePreview;

@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, assign) BOOL isProcessing;

@end

@implementation IUFiltersViewController

#pragma mark - Custom setters/getters

- (void)setImage:(IUImage *)image {
    
    _image = image;
    
    self.appliedFiltersArray = [_image.filters mutableCopy];
    self.filterImagePreview = _image.processedImage;
    
    [self.collectionView reloadData];
}

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
       
        //Prepare global Core image context to reuse
        //Create a CIContext object from an EAGL context to avoid unnecessary texture transfers between the CPU and GPU.
        EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        //disable color management to boost performance
        NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null] };
        
        self.ciContext = [CIContext contextWithEAGLContext:myEAGLContext options:options];

        [self prepareFilters];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)prepareFilters {
    
    //Prepare filters array
    
    self.filtersArray = @[ [[IUFilter alloc] initWithCIFilterName:@"CIPhotoEffectChrome"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIPhotoEffectInstant"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIPhotoEffectMono"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIPhotoEffectNoir"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIPhotoEffectProcess"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIColorMonochrome"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIColorInvert"],
                           [[IUFilter alloc] initWithCIFilterName:@"CIColorPosterize"]];
}

#pragma mark - Page lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    //if currently processing image disable further actions
    if (self.isProcessing) {
        return;
    }
    
    IUFilterCollectionViewCell *filterCell = (IUFilterCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    //find coresponding filter in applied filters and remove it or add it if not there
    NSInteger index =  [self.appliedFiltersArray indexOfObjectPassingTest:^BOOL(IUFilter *filter, NSUInteger idx, BOOL *stop) {
        if ([filterCell.filter.ciFilter.name isEqualToString:filter.ciFilter.name]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    
    if (index != NSNotFound) {

        [self.appliedFiltersArray removeObjectAtIndex:index];

    }
    else {
        
        [self.appliedFiltersArray addObject:filterCell.filter];
    }
    
    [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(filtersControllerWillStartToApplyFilters:)]) {
            [self.delegate filtersControllerWillStartToApplyFilters:self];
        }
    }
    
    self.isProcessing = YES;
    
    [self applyFiltersWithCompletionBlock:^(UIImage *processedImage) {
        
        self.filterImagePreview = processedImage;
        
        self.isProcessing = NO;
        
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(filtersControllerDidApplyFilters:)]) {
                [self.delegate filtersControllerDidApplyFilters:self];
            }
        }
    }];
    

}

#pragma mark - UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
   
    return [self.filtersArray count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    IUFilterCollectionViewCell *filterCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"filterCollectionViewCell" forIndexPath:indexPath];
    
    IUFilter *filterForCell = (IUFilter *)self.filtersArray[indexPath.row];
    
    [filterCell setupCellWithFilter:filterForCell andImage:self.image];
    
    NSInteger index =  [self.appliedFiltersArray indexOfObjectPassingTest:^BOOL(IUFilter *filter, NSUInteger idx, BOOL *stop) {
        if ([filterForCell.ciFilter.name isEqualToString:filter.ciFilter.name]) {
            *stop = YES;
            return YES;
        }
        
        return NO;
    }];
    
    if (index != NSNotFound) {
        filterCell.active = YES;
    }
    else {
        filterCell.active = NO;
    }
    
    return filterCell;
}

- (void)applyFiltersWithCompletionBlock:(callBackBlock)block {
    
    //based on Apple: "each thread must create its own CIFilter objects. Otherwise, your app could behave unexpectedly."
    NSMutableArray *filterArrayForThread = [self.appliedFiltersArray copy];
    
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        
        NSMutableArray *filterArray = filterArrayForThread;
        
        UIImageOrientation originalOrientation = self.image.imageReadyToProcess.imageOrientation;
        CGFloat originalScale = self.image.imageReadyToProcess.scale;
        
        CIImage *result = [CIImage imageWithCGImage:self.image.imageReadyToProcess.CGImage];
        
        for (IUFilter *filter in filterArray) {
            
            result = [filter applyFilterToImage:result];
        }
        
        CGRect extent = [result extent];
        
        CGImageRef cgImage = [self.ciContext createCGImage:result fromRect:extent];
        
        UIImage *outputImage = [UIImage imageWithCGImage:cgImage scale:originalScale orientation:originalOrientation];
        
        CGImageRelease(cgImage);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(outputImage);
            }
        });
        
    });
    
}

@end
