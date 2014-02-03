//
//  GRKAlbumPhotosListThumbnail.m
//  grabKit
//
//  Created by imac on 03/02/14.
//
//

#import "GRKAlbumPhotosListThumbnail.h"
#import "GRKPickerViewController.h"
#import "NZCircularImageView.h"

@implementation GRKAlbumPhotosListThumbnail

-(id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self buildViews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildViews];
    }
    return self;
}

-(void) buildViews {

    CGRect thumbnailRect = CGRectMake(1, 1, self.bounds.size.width -2 , self.bounds.size.height -2 );
    albumThumbnailImageView = [[NZCircularImageView alloc] initWithFrame:thumbnailRect];
    [self.contentView addSubview:albumThumbnailImageView];
}



-(void) prepareForReuse {
    
    [albumThumbnailImageView setImage:nil];
    self.selected = NO;
    
}

-(void)updateAlbumThumbnailWithImage:(UIImage*)image  animated:(BOOL)animated; {
    
    if ( albumThumbnailImageView.image == nil  &&  animated ){
        
        albumThumbnailImageView.alpha = .0;
        albumThumbnailImageView.image = image;
        
        [UIView animateWithDuration:0.33 animations:^{
            
            albumThumbnailImageView.alpha = 1.;
            
        } completion:^(BOOL finished) {
            
        }];
        
    } else {
        
        // UI updates must be done on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            albumThumbnailImageView.image = image;
            
        });
        
        
    }
    
    
}

-(void) setSelected:(BOOL)selected {
    [super setSelected:selected];
}


@end
