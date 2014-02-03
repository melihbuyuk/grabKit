//
//  GRKAlbumPhotosListThumbnail.h
//  grabKit
//
//  Created by imac on 03/02/14.
//
//

#import <UIKit/UIKit.h>
#import "NZCircularImageView.h"


/* This class is not meant to be used as-is by third-party developers. The comments are here just for eventual needs of customisation .
 
 This class is a subclass of UICollectionViewCell used in GRKPickerPhotosList, and in GRKPickerAlbumsListCell.
 
 It displays a default gray square, until the method updateThumbnailWithImage:animated: is called.
 
 It also handles a UIImageView "selectedImageView", shown or hidden according to the cell's state.
 
 */
@interface GRKAlbumPhotosListThumbnail : UICollectionViewCell {    
    NZCircularImageView * albumThumbnailImageView;
}

-(void)updateAlbumThumbnailWithImage:(UIImage*)image animated:(BOOL)animated;

@end
