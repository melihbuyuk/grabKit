//
//  GRKPickerCropViewController.h
//  grabKit
//
//  Created by imac on 04/02/14.
//
//

#import <UIKit/UIKit.h>
#import "VPImageCropperViewController.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

#import "GRKServiceGrabber.h"
#import "GRKAlbum.h"

@interface GRKPickerCropViewController : UIViewController
{
    GRKServiceGrabber * _grabber;
    NSURL * _album;
}

@property (nonatomic, readonly) NSURL * album;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andGrabber:(GRKServiceGrabber*)grabber andAlbum:(NSURL*)album;

@end
