//
//  IUImageViewController.h
//  Image Uploader
//
//  Created by Adrian Adamkovic on 25/12/13.
//  Copyright (c) 2013 Adrian Adamkovic. All rights reserved.
//
//  Description: Image controller for controlling image manipulation

#import <UIKit/UIKit.h>
#import "IUFiltersViewController.h"

@interface IUImageViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IUFiltersControllerDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate>


@end
