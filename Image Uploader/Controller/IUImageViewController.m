//
//  IUImageViewController.m
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Image controller for controlling image manipulation

#import "IUImageViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "IUImage.h"
#import "IUFiltersViewController.h"
#import "IULoadingOverlayView.h"
#import "UIImage+ImageUploaderExtensions.h"

#define CLEAR_ACTION_SHEET_TAG 1001
#define IMAGE_SOURCE_ACTION_SHEET_TAG 1002

static NSString * const tutorialShownUserDefaultsKey = @"tutorialShown";

@interface IUImageViewController ()

//IBOutlets
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *filtersContainerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearbarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filtersBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *noImageLabel;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;

@property (nonatomic, strong) IULoadingOverlayView *loadingOverlay;

//Class properties
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) IUImage *currentImage;
@property (nonatomic, weak) IUFiltersViewController *filtersViewController;
@property (nonatomic, strong) UIPopoverController *currentPopover;

//Helpers
@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, assign) BOOL isProcessing;

@end

@implementation IUImageViewController

#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Page life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self refreshControls];
    
    //Init loading view
    self.loadingOverlay = [IULoadingOverlayView loadingView];
    [self.view addSubview:self.loadingOverlay];
    
    //show tutorial about preview image - only once
    if (![[[NSUserDefaults standardUserDefaults] valueForKey:tutorialShownUserDefaultsKey] boolValue]) {
      
        UIAlertView *tutorialAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Did you know?", nil)
                                                                    message:NSLocalizedString(@"By holding on image you can compare the original image with the image with filters applied", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
        
        [tutorialAlertView show];
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:tutorialShownUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
}

- (void)viewDidLayoutSubviews {
    
    //update loading frame
    self.loadingOverlay.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    
    //update filters container frame based on current mode
    self.isEditMode ? [self showFiltersContainerAnimated:NO] : [self hideFiltersContainerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Seque methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    //assign reference of child view controller from storyboard
    if ([segue.identifier isEqualToString:@"iu_filters_embed"]) {
        self.filtersViewController = segue.destinationViewController;
        self.filtersViewController.delegate = self;
    }
}

#pragma mark - User interaction

//Show preview of original picture to user for comparing purpose
- (IBAction)switchPreviewToProcessedImage:(id)sender {
    
    self.imageView.image = self.isEditMode ? self.filtersViewController.filterImagePreview : self.currentImage.processedImage;
}

- (IBAction)switchPreviewToOriginalImage:(id)sender {
    
    self.imageView.image = self.currentImage.imageReadyToProcess;
}

- (IBAction)shareImage:(id)sender {
    
    //Share processed image on twitter/facebook
    NSArray *activityItems = @[self.currentImage.processedImage];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc]
                                                    initWithActivityItems:activityItems
                                                    applicationActivities:nil];
    
    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)showClearActionSheet:(id)sender {
    
    //Let the user to confirm to clear all changes
    UIActionSheet *clearActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"Remove all changes",nil];
    
    clearActionSheet.tag = CLEAR_ACTION_SHEET_TAG;
    
    [clearActionSheet showFromBarButtonItem:self.clearbarButtonItem animated:YES];
    
}


- (IBAction)showFilters:(id)sender {
    
    [self showFiltersContainerAnimated:YES];
}

- (void)showImageSourceActionSheet:(id)sender {
    
    //Check if different image sources are available and let user choose one
    
    UIActionSheet *imageSourceActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                        delegate:self
                                                               cancelButtonTitle:nil
                                                          destructiveButtonTitle:nil
                                                               otherButtonTitles:nil];
    
    imageSourceActionSheet.tag = IMAGE_SOURCE_ACTION_SHEET_TAG;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        [imageSourceActionSheet addButtonWithTitle:NSLocalizedString(@"Take photo", nil)];
        
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        [imageSourceActionSheet addButtonWithTitle:NSLocalizedString(@"Choose existing photo", nil)];
    }
    
    if (imageSourceActionSheet.numberOfButtons > 0) {
    
        //Add cancel button at the end
        [imageSourceActionSheet addButtonWithTitle:@"Cancel"];
        imageSourceActionSheet.cancelButtonIndex = imageSourceActionSheet.numberOfButtons - 1;
        
        [imageSourceActionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }
}

#pragma mark - UIImagepicker methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    if (self.currentPopover) {
        
        [self.currentPopover dismissPopoverAnimated:YES];
        
        self.currentPopover = nil;
    }
    else {
        
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToUse;
    
    // Handle a still image picked from a photo album
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToUse = editedImage;
        } else {
            imageToUse = originalImage;
        }
        
        //create image object
        self.currentImage = [[IUImage alloc] initWithImage:imageToUse];
        
        //scale image size if more then allowed size for processing
        if(self.filtersViewController.ciContext.inputImageMaximumSize.width > self.currentImage.originalImage.size.width &&
           self.filtersViewController.ciContext.inputImageMaximumSize.height > self.currentImage.originalImage.size.height ){
            
            self.currentImage.imageReadyToProcess = self.currentImage.originalImage;
        }
        else {
         
            self.currentImage.imageReadyToProcess = [UIImage resizeImagePreservingAspectRatio:self.currentImage.originalImage resizeSize:self.filtersViewController.ciContext.inputImageMaximumSize];
        }
        
        self.imageView.image = self.currentImage.processedImage;
        
        self.noImageLabel.hidden = YES;
        
    }
    
    if (self.currentPopover) {
        
        [self.currentPopover dismissPopoverAnimated:YES];
        
        self.currentPopover = nil;
    }
    else {
        
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self refreshControls];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
       
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
        
        [popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        
        self.currentPopover = popover;
    
    } else {
        
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.cancelButtonIndex == buttonIndex) return;
    
    if (actionSheet.tag == IMAGE_SOURCE_ACTION_SHEET_TAG) {
        
        //As we have dynamically created UIActionSheet we have to compare button based on title not button index
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Take photo", nil)]) {
            
            //show camera
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Choose existing photo", nil)]) {
            
            //show photo library
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            
        }
    }
    else if (actionSheet.tag == CLEAR_ACTION_SHEET_TAG) {
        
        [self clearFilters];
        
    }
}

#pragma mark - Filters container view methods

- (void)hideFiltersContainerAnimated:(BOOL)animated {
    
    CGRect finalRect = CGRectMake(0.0f,
                                  self.view.frame.size.height + self.filtersContainerView.frame.size.height,
                                  self.view.frame.size.width,
                                  self.filtersContainerView.frame.size.height);
    if (animated) {
        
        [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            self.filtersContainerView.frame = finalRect;
            
        } completion:nil];

    }
    else {
        
        self.filtersContainerView.frame = finalRect;
    }
    
    self.isEditMode = NO;
    [self refreshControls];
}



- (void)showFiltersContainerAnimated:(BOOL)animated {

    self.filtersViewController.image = self.currentImage;
    
    CGRect finalRect = CGRectMake(0.0f,
                                  self.view.frame.size.height - self.filtersContainerView.frame.size.height,
                                  self.view.frame.size.width,
                                  self.filtersContainerView.frame.size.height);
    if (animated) {
        
        [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
            
            self.filtersContainerView.frame = finalRect;
        
        } completion:nil];
    }
    else {
        
        self.filtersContainerView.frame = finalRect;
    }
    
    self.isEditMode = YES;
    [self refreshControls];
}

#pragma mark - Edit mode methods

- (void)clearFilters {
    
    //Remove all filters applied
    self.currentImage.processedImage = self.currentImage.imageReadyToProcess;
    [self.currentImage.filters removeAllObjects];
    
    self.imageView.image = self.currentImage.processedImage;
}

- (void)applyFilters:(id)sender {
    
    self.currentImage.processedImage = self.filtersViewController.filterImagePreview;
    self.currentImage.filters = [self.filtersViewController.appliedFiltersArray mutableCopy];
    
    self.imageView.image = self.currentImage.processedImage;
    
    [self hideFiltersContainerAnimated:YES];
    
}

- (void)cancelFilters:(id)sender {
    
    self.isProcessing = NO;
    
    self.imageView.image = self.currentImage.processedImage;
    
    [self hideFiltersContainerAnimated:YES];
}

#pragma mark - IUFiltersControllerDelegate methods

- (void)filtersControllerWillStartToApplyFilters:(IUFiltersViewController *)controller {
    
    self.isProcessing = YES;
    
    [self refreshControls];
}

- (void)filtersControllerDidApplyFilters:(IUFiltersViewController *)controller {
    
    if (self.isEditMode) {
       
        self.isProcessing = NO;
        
        [self refreshControls];
        
        self.imageView.image = controller.filterImagePreview;
    }
    }

#pragma mark - Navigation items controls methods

- (void)refreshControls {
    
    self.loadingOverlay.hidden = !self.isProcessing;
    
    
    //add navigation items based on current mode
    if (self.isEditMode) {
        
        //Change navigation bar tint and style to indicate that we are in edit mode
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = [UIColor blueColor];
        
        self.navigationItem.title = NSLocalizedString(@"Choose Filter", nil);
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Apply", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(applyFilters:)];
        
        self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(cancelFilters:)];
        
        
        self.navigationItem.rightBarButtonItem.enabled = !self.isProcessing;
        
    }
    else {
       
        
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = [UIColor redColor];
        
        self.navigationItem.title = NSLocalizedString(@"Image Uploader", nil);
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", nil)
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(showImageSourceActionSheet:)];
        
        self.navigationItem.leftBarButtonItem = nil;
        
        
        //Disable some controls if no image is present
        if (!self.currentImage) {
            
            self.clearbarButtonItem.enabled = NO;
            self.filtersBarButtonItem.enabled = NO;
            self.shareBarButtonItem.enabled = NO;
        }
        else {
            
            self.clearbarButtonItem.enabled = YES;
            self.filtersBarButtonItem.enabled = YES;
            self.shareBarButtonItem.enabled = YES;
            
        }
    }
}



@end
