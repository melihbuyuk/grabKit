/*
 * This file is part of the GrabKit package.
 * Copyright (c) 2013 Pierre-Olivier Simonard <pierre.olivier.simonard@gmail.com>
 *  
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
 * associated documentation files (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the 
 * following conditions:
 *  
 * The above copyright notice and this permission notice shall be included in all copies or substantial 
 * portions of the Software.
 *  
 * The Software is provided "as is", without warranty of any kind, express or implied, including but not 
 * limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no
 * event shall the authors or copyright holders be liable for any claim, damages or other liability, whether
 * in an action of contract, tort or otherwise, arising from, out of or in connection with the Software or the 
 * use or other dealings in the Software.
 *
 * Except as contained in this notice, the name(s) of (the) Author shall not be used in advertising or otherwise
 * to promote the sale, use or other dealings in this Software without prior written authorization from (the )Author.
 */

#import "GRKPickerViewController.h"
#import "GRKPickerViewController+privateMethods.h"
#import "GRKPickerAlbumsList.h"
#import "GRKServiceGrabberConnectionProtocol.h"
#import "GRKPickerPhotosList.h"
#import "GRKPickerAlbumsListCell.h"

#import "MBProgressHUD.h"

#import "GRKServiceGrabber+usernameAndProfilePicture.h"
#import "GRKDeviceGrabber.h"

#import "GRKPickerThumbnailManager.h"

#import <FacebookSDK/FacebookSDK.h>

#import "AsyncURLConnection.h"



static NSString *loadMoreCellIdentifier = @"loadMoreCell";

@interface GRKPickerAlbumsList()
    -(void)loadMoreAlbums;
    -(void)setState:(GRKPickerAlbumsListState)newState;
    -(void)showHUD;
    -(void)hideHUD;
@end


NSUInteger kNumberOfAlbumsPerPage = 8;
NSUInteger kMaximumRetriesCount = 1;

@implementation GRKPickerAlbumsList

@synthesize tableView = _tableView;
@synthesize serviceName = _serviceName;

-(void) dealloc {
    
    for( GRKAlbum * album in _albums ){
        [album removeObserver:self forKeyPath:@"count"];
    }
}


-(id) initWithGrabber:(id)grabber andServiceName:(NSString *)serviceName
{
    self = [super initWithNibName:@"GRKPickerAlbumsList" bundle:GRK_BUNDLE];
    if ( self ){
        _grabber = grabber;
        _serviceName = serviceName;
        _albums = [[NSMutableArray alloc] init];
        _lastLoadedPageIndex = 0;
        allAlbumsGrabbed = NO;
        [self setState:GRKPickerAlbumsListStateInitial];
        
    }
    return self;
}

-(NSInteger)numberOfRowsInTotal{
    NSInteger sections = [_albums count];
    NSInteger cellCount = 0;
    for (NSInteger i = 0; i < sections; i++) {
        GRKAlbum * albumAtTotal = (GRKAlbum*)[_albums objectAtIndex:i];
        cellCount += albumAtTotal.count;
    }
    
    return cellCount;
}

/* This state design-pattern must be used to update UI only. */

-(void) setState:(GRKPickerAlbumsListState)newState
{
    state = newState;
    switch (newState)
    {
        case GRKPickerAlbumsListStateConnecting: {
            _needToConnectView.hidden = YES;
            [self showHUD];
            INCREASE_OPERATIONS_COUNT
        }
        break;
        
        case GRKPickerAlbumsListStateNeedToConnect:{
            DECREASE_OPERATIONS_COUNT
            _needToConnectView.alpha = 0;
            _needToConnectView.hidden = NO;
            _needToConnectLabel.hidden = YES;
            _needToConnectView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-view.png",[_grabber.serviceName lowercaseString]]]];
            [_connectButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-login.png",[_grabber.serviceName lowercaseString]]] forState:UIControlStateNormal];
            
            [UIView animateWithDuration:0.33 animations:^{
                _needToConnectView.alpha = 1;
                [self hideHUD];
            }];
        }
        break;
            
        case GRKPickerAlbumsListStateConnected: {
            DECREASE_OPERATIONS_COUNT
            if ( ! [_grabber isKindOfClass:[GRKDeviceGrabber class]]) {
//                [self buildHeaderView];
            }
        }
        break;
            
        case GRKPickerAlbumsListStateDidNotConnect: {
            DECREASE_OPERATIONS_COUNT
            [self.navigationController popViewControllerAnimated:YES];
        }
        break;
            
        case GRKPickerAlbumsListStateConnectionFailed: {
            DECREASE_OPERATIONS_COUNT
            _needToConnectView.alpha = 0;
            _needToConnectView.hidden = NO;
            _needToConnectLabel.text = GRK_i18n(@"GRK_ALBUMS_LIST_ERROR_RETRY", @"An error occured. Please try again.");
            
            [UIView animateWithDuration:0.33 animations:^{
                _needToConnectView.alpha = 1;
                [self hideHUD];
            }];
        }
        break;
        
        case GRKPickerAlbumsListStateGrabbing: {
            INCREASE_OPERATIONS_COUNT
            if ( [MBProgressHUD HUDForView:self.view] == nil ){
                [self showHUD];
            }
        }
        break;

        // When some albums are grabbed, reload the tableView
        case GRKPickerAlbumsListStateAlbumsGrabbed:
        case GRKPickerAlbumsListStateAllAlbumsGrabbed:    
        {
            DECREASE_OPERATIONS_COUNT
            if ( self.tableView.hidden  ){
                self.tableView.alpha = 0;
                self.tableView.hidden = NO;
                
                // And animate the have a nice transition between the HUD and the tableView
                [UIView animateWithDuration:0.33 animations:^{
                    
                    self.tableView.alpha = 1;
                    [self hideHUD];
                    
                }];
                
            } else {
                // else, just hide the HUD
                [self hideHUD];
                
            }
            
            // If all the albums have been grabbed, show a nice footer
            if ( state == GRKPickerAlbumsListStateAllAlbumsGrabbed ){
                [self buildOrUpdateFooterView];
            }
            
            [self.tableView reloadData];
            NSLog(@"%d", [self numberOfRowsInTotal]);
            NSLog(@"%d", [_albums count]);
            
        }
            break;
        
        case GRKPickerAlbumsListStateGrabbingFailed:
        {
            DECREASE_OPERATIONS_COUNT
            
            NSIndexPath * loadMoreCellIndexPath = [NSIndexPath indexPathForRow:[_albums count] inSection:0];
            UITableViewCell * loadMoreCell = [_tableView cellForRowAtIndexPath:loadMoreCellIndexPath];
            
            if ( [loadMoreCell isKindOfClass:[GRKPickerLoadMoreCell class]] ){
            
                [(GRKPickerLoadMoreCell*)loadMoreCell setToRetry];
            }
            
            [self hideHUD];
            
        }
            break;
            
        case GRKPickerAlbumsListStateDisconnecting:
        {
            INCREASE_OPERATIONS_COUNT

            [self showHUD];
            
        }
            break;
            
            
        case GRKPickerAlbumsListStateDisconnected:
        {
             DECREASE_OPERATIONS_COUNT
            
             [self hideHUD];
            
             [self.navigationController popToRootViewControllerAnimated:YES];
         
        }
            break;
            
            
        case GRKPickerAlbumsListStateError:
        {
            DECREASE_OPERATIONS_COUNT
            
            [self hideHUD];

        }
            break;
            
        default:
            break;
    }
    
    
}

-(void)showHUD
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Yukleniyor";
}

-(void)hideHUD {
    [MBProgressHUD  hideHUDForView:self.view animated:YES];
}

-(void) buildOrUpdateFooterView {
    
    if ( _footer == nil ){
        _footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 80)];
        
    }
    
    
    NSString * stringAllLoaded = GRK_i18n(@"GRK_ALBUMS_LIST_ALL_ALBUMS_LOADED", @"All albums loaded");
    
    UIFont * fontAllLoaded = [UIFont fontWithName:@"Helvetica" size:14];
    
    CGSize expectedSize = [stringAllLoaded sizeWithFont:fontAllLoaded
                                      constrainedToSize:_footer.frame.size
                                          lineBreakMode:NSLineBreakByTruncatingTail];
    
    CGFloat labelX = (_footer.frame.size.width - expectedSize.width) / 2;
    CGFloat labelY = (_footer.frame.size.height - expectedSize.height) / 2;
    
    UILabel * labelAllLoaded = [[UILabel alloc] initWithFrame:CGRectMake( labelX, labelY, expectedSize.width, expectedSize.height)];
    labelAllLoaded.text = stringAllLoaded;
    labelAllLoaded.font = fontAllLoaded;
    labelAllLoaded.textColor = [UIColor blackColor];
    
    [_footer addSubview:labelAllLoaded];
    
    self.tableView.tableFooterView = _footer;
    
}


#pragma mark GRKPickerCurrentUserViewDelegate methods

-(void) headerViewDidTouchLogoutButton:(id)headerView {
    
    
    [self setState:GRKPickerAlbumsListStateDisconnecting];
    
    // First, cancel all the running queries
    [_grabber cancelAllWithCompleteBlock:^(NSArray *results) {
        
            [(GRKServiceGrabber<GRKServiceGrabberConnectionProtocol> *)_grabber disconnectWithDisconnectionIsCompleteBlock:^(BOOL disconnected) {
            
            [self setState:GRKPickerAlbumsListStateDisconnected];
            
        } andErrorBlock:^(NSError *error) {
            
            NSLog(@" An error occured trying to disconnect the grabber %@", _grabber);
            NSLog(@" error : %@", error);
           
            // set to disconnected anyway, to fail silently
            [self setState:GRKPickerAlbumsListStateDisconnected];

            
        }];
        
    }];

    
}

#pragma mark GRKPickerLoadMoreCellDelegate 

-(void)cellDidReceiveTouchOnLoadMoreButton:(GRKPickerLoadMoreCell *)cell {
    
    if ( state == GRKPickerAlbumsListStateGrabbing ){
        return;
    }
    
    if ( ! allAlbumsGrabbed ){
        [self loadMoreAlbums];
        
    } else {
        [self.tableView reloadData];
        
    }
    
}


-(void) didTouchCancelButton {
    
    [[GRKPickerViewController sharedInstance] dismiss];
    
}

-(IBAction)didTouchConnectButton {
    
    
    [self setState:GRKPickerAlbumsListStateConnecting];
    
    [(id<GRKServiceGrabberConnectionProtocol>)_grabber connectWithConnectionIsCompleteBlock:^(BOOL connected) {
    
        if ( connected ) {
            
            [self setState:GRKPickerAlbumsListStateConnected];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self loadMoreAlbums];
                
            });
            
        } else {
            
            [self setState:GRKPickerAlbumsListStateDidNotConnect];
            
        }
        
    } andErrorBlock:^(NSError *error) {
        
        [self setState:GRKPickerAlbumsListStateConnectionFailed];
        NSLog(@" an error occured trying to connect the grabber : %@", error);
        
        
    }];

    
    
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.tableView.rowHeight = 90.0;
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // If the navigation bar is translucent, it'll recover the top part of the tableView
    // Let's add some inset to the tableView to avoid this
    // Nevertheless, we don't need to do it when the picker is in a popover, because the navigationBar is not visible
    if ( ! [[GRKPickerViewController sharedInstance] isPresentedInPopover] && self.navigationController.navigationBar.translucent ){

        self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
        
    }

    if ( ! [@[@"7.0"] containsObject:[[UIDevice currentDevice] systemVersion]] ){
        
        	self.tableView.contentOffset = CGPointZero;
	        self.tableView.contentInset = UIEdgeInsetsZero;
    }

    
}

-(void)back {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.title = _serviceName;
    
    if ( state != GRKPickerAlbumsListStateInitial )
        return;
    
    
    UIImage *buttonImage = [UIImage imageNamed:@"social-back.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:buttonImage forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height);
    [button addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *customBarItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    UIImage *buttonCancel = [UIImage imageNamed:@"social-cancel.png"];
    UIButton *buttonclose = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonclose setImage:buttonCancel forState:UIControlStateNormal];
    buttonclose.frame = CGRectMake(0, 0, buttonCancel.size.width, buttonCancel.size.height);
    [buttonclose addTarget:self action:@selector(didTouchCancelButton) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancelBarItem = [[UIBarButtonItem alloc] initWithCustomView:buttonclose];
    
    self.navigationItem.leftBarButtonItem = customBarItem;
    
    self.navigationItem.rightBarButtonItem = cancelBarItem;
    
    
    [self setState:GRKPickerAlbumsListStateConnecting];

    
    // If the grabber needs to connect
    if ( _grabber.requiresConnection ){
        
        
        [(id<GRKServiceGrabberConnectionProtocol>)_grabber isConnected:^(BOOL connected) {
            
            if ( ! connected ){
                [self setState:GRKPickerAlbumsListStateNeedToConnect];
            
            } else {

                dispatch_async(dispatch_get_main_queue(), ^(void){

                    [self setState:GRKPickerAlbumsListStateConnected];
                    // start grabbing albums
                    [self loadMoreAlbums];   

                });

            }
            
        } errorBlock:^(NSError *error) {
            
            NSLog(@" an error occured trying to check if the grabber is connected : %@", error);
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                
                [self setState:GRKPickerAlbumsListStateConnectionFailed];
            
            });
            
        }];
                
    } else {
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            [self setState:GRKPickerAlbumsListStateConnected];
            // start grabbing albums ( we don't need to add the "log out" button, as the grabber doesn't need to connect ...)
            [self loadMoreAlbums];   
            
        });

    }
    

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_grabber cancelAll];

    // Reset the operations count.
    // If the view disappears while something is (i.e. after a INCREASE_OPERATIONS_COUNT),
    //  the corresponding DECREASE_OPERATIONS_COUNT is not called, and the activity indicator remains spinning...
    RESET_OPERATIONS_COUNT
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return ( interfaceOrientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationIsLandscape(interfaceOrientation) );
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ( [[GRKPickerViewController sharedInstance] isPresentedInPopover] || ! self.navigationController.navigationBar.translucent ){
        return;
    }
    CGFloat top; // The top value of the content inset
    BOOL shouldScrollToTop = NO;
    
    CGFloat navigationBarHeightLandscape = 32;
    CGFloat navigationBarHeightPortrait = 44;
    
    // If we are rotating to Landscape ...
    if (  UIInterfaceOrientationIsLandscape(toInterfaceOrientation)   ){
        top = navigationBarHeightLandscape;
        shouldScrollToTop = ( self.tableView.contentOffset.y ==  - navigationBarHeightPortrait );
        
    } else {
        top = navigationBarHeightPortrait;
        shouldScrollToTop = ( self.tableView.contentOffset.y ==  - navigationBarHeightLandscape );
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0);
        if ( shouldScrollToTop ){
            self.tableView.contentOffset = CGPointMake(0, - top);
        }
    }];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSIndexPath * loadMoreCellIndexPath = [NSIndexPath indexPathForRow:[_albums count] inSection:0];
    UITableViewCell * loadMoreCell = [_tableView cellForRowAtIndexPath:loadMoreCellIndexPath];
    
    if ( [loadMoreCell isKindOfClass:[GRKPickerLoadMoreCell class]] ){
        [(GRKPickerLoadMoreCell*)loadMoreCell updateButtonFrame];
    }
}

-(void) prepareCell:(GRKPickerAlbumsListCell *)cell fromTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath withAlbum:(GRKAlbum*)album
{
    [cell setAlbum:album];

    if ( album.coverPhoto == nil && [album.coverPhoto.images count] == 0 )
        return;

    NSURL * thumbnailURL = nil;
    NSUInteger minWidth = cell.thumbnail.frame.size.width * 2;
    NSUInteger minHeight = cell.thumbnail.frame.size.height * 2;
    
    NSArray * imagesSortedByHeight = [album.coverPhoto imagesSortedByHeight];
    for( GRKImage * image in imagesSortedByHeight ){
        if ( image.width >= minWidth && image.height >= minHeight ) {
            thumbnailURL = image.URL;
            break;
        }
    }
    if ( thumbnailURL == nil ){
        thumbnailURL = ((GRKImage*)[imagesSortedByHeight lastObject]).URL;
    }
    UIImage * cachedThumbnail = [[GRKPickerThumbnailManager sharedInstance] cachedThumbnailForURL:thumbnailURL andSize:CGSizeMake(minWidth, minHeight)];
    
    if ( cachedThumbnail == nil ) {
        [[GRKPickerThumbnailManager sharedInstance] downloadThumbnailAtURL:thumbnailURL forThumbnailSize:CGSizeMake(minWidth, minHeight) withCompleteBlock:^( UIImage *image, BOOL retrievedFromCache )
        {
            if ( image != nil ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    GRKPickerAlbumsListCell * cellToUpdate = (GRKPickerAlbumsListCell *)[tableView cellForRowAtIndexPath:indexPath];
                    [cellToUpdate updateThumbnailWithImage:image animated: ! retrievedFromCache ];
                });
            }
        } andErrorBlock:^(NSError *error) {
        
        }];
    }else {
        [cell updateThumbnailWithImage:cachedThumbnail animated:NO];
    }
}



#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    NSUInteger res = [_albums count];
        
    // If some albums have been grabbed, show an extra cell for "N albums - Load More"
    if ( state == GRKPickerAlbumsListStateAlbumsGrabbed ) res++;
    
    // If all albums have been grabbed, show an extra cell for "N Albums"
  //  if ( state == GRKPickerAlbumsListStateAllAlbumsGrabbed ) res++;
    
    return res;

    
    
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    // Handle the extra cell
    if ( indexPath.row >= [_albums count] ){
    
        if ( ! allAlbumsGrabbed ){

            cell = [tableView dequeueReusableCellWithIdentifier:loadMoreCellIdentifier];
            cell = [[GRK_BUNDLE loadNibNamed:@"GRKPickerLoadMoreCell" owner:nil options:nil] objectAtIndex:0];
            ((GRKPickerLoadMoreCell*)cell).delegate = self;
            [(GRKPickerLoadMoreCell*)cell setToLoadMore];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
    } else {
        
        static NSString *CellIdentifier = @"AlbumCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            
            cell = [[GRK_BUNDLE loadNibNamed:@"GRKPickerAlbumsListCell" owner:nil options:nil] objectAtIndex:0];
        }
        
        GRKAlbum * albumAtIndexPath = (GRKAlbum*)[_albums objectAtIndex:indexPath.row];
        
        [self prepareCell:(GRKPickerAlbumsListCell*)cell fromTableView:tableView atIndexPath:indexPath withAlbum:albumAtIndexPath];
        
        if ( albumAtIndexPath.count > 0 ){
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        
        
    }

    cell.selected = NO;
    
    return cell;
}



-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ( [cell isKindOfClass:[GRKPickerLoadMoreCell class]]) {
        [(GRKPickerLoadMoreCell*)cell updateButtonFrame];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];

    if ( indexPath.row <= [_albums count] -1 ) {
        
        GRKAlbum * albumAtIndexPath = [_albums objectAtIndex:indexPath.row];
        
        if ( albumAtIndexPath.count  > 0 ){
        
            GRKPickerPhotosList * photosList = [[GRKPickerPhotosList alloc] initWithNibName:@"GRKPickerPhotosList" bundle:GRK_BUNDLE andGrabber:_grabber andAlbum:albumAtIndexPath];
            [self.navigationController pushViewController:photosList animated:YES];
        }
        
    }

}


#pragma mark - 


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    
    if ( [keyPath isEqualToString:@"count"] ){
        
        NSInteger indexOfAlbum = [_albums indexOfObject:object];

        if ( indexOfAlbum != NSNotFound ){
            
            NSArray * indexPathsToReload = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexOfAlbum inSection:0]];
            [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];    
        }
        
    }
    
}

-(void) loadCoverPhotoForAlbums:(NSArray*)albums {
    
    // First, filter to retreive only the albums without cover
    NSMutableArray * albumsWithoutCover = [NSMutableArray array];
    for( GRKAlbum * album in albums ){
        if ( album.coverPhoto == nil ){
            [albumsWithoutCover addObject:album];
        }
    }

    
    INCREASE_OPERATIONS_COUNT
    
    // Fill these albums with their cover photo
    [_grabber fillCoverPhotoOfAlbums:albumsWithoutCover withCompleteBlock:^(id result) {

        
        DECREASE_OPERATIONS_COUNT
        
        if ( state == GRKPickerAlbumsListStateGrabbing ){
            
            // Do no reload rows during a grab of data. 2 reloads on the tableView could generate a crash
            return;
        }
            
        
        // for each album filled, find its index in the _albums array, and build an NSIndexPath to reload the tableView
        
        NSMutableArray * indexPathsToReload = [NSMutableArray array];
        
        for( GRKAlbum * a in result ) {
            
            NSUInteger indexOfFilledAlbum = [_albums indexOfObject:a];
            if ( indexOfFilledAlbum != NSNotFound ){
                [indexPathsToReload addObject:[NSIndexPath indexPathForRow:indexOfFilledAlbum inSection:0]];
                
            }
            
        }
        
        [self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationNone];
        
        
    } andErrorBlock:^(NSError *error) {
        
        // Do nothing, fail silently.
        DECREASE_OPERATIONS_COUNT
        
    }];
    
    
}



-(void) loadMoreAlbums {

    if ( state == GRKPickerAlbumsListStateGrabbing)
        return;
    
    
    [self loadAlbumsAtPageIndex:_lastLoadedPageIndex withNumberOfAlbumsPerPage:kNumberOfAlbumsPerPage andNumberOfAllowedRetries:kMaximumRetriesCount];
    
}

-(void) loadAlbumsAtPageIndex:(NSUInteger)pageIndex withNumberOfAlbumsPerPage:(NSUInteger)numberOfAlbumsPerPage andNumberOfAllowedRetries:(NSUInteger)allowedRetriesCount {
    
    if ( state != GRKPickerAlbumsListStateGrabbing)
        [self setState:GRKPickerAlbumsListStateGrabbing];
    
    [_grabber albumsOfCurrentUserAtPageIndex:pageIndex
                   withNumberOfAlbumsPerPage:numberOfAlbumsPerPage
                            andCompleteBlock:^(NSArray *results) {
                                
                                _lastLoadedPageIndex+=1;
                                [_albums addObjectsFromArray:results];
                                
                                for( GRKAlbum * newAlbum in results ){
                                    
                                    [newAlbum addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
                                    
                                }
                              
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self loadCoverPhotoForAlbums:results];
                                });
                                
                                
                                // Update the state. the tableView is reloaded in this method.
                                if ( [results count] < kNumberOfAlbumsPerPage ){
                                    allAlbumsGrabbed = YES;
                                    [self setState:GRKPickerAlbumsListStateAllAlbumsGrabbed];
                                } else {
                                    [self setState:GRKPickerAlbumsListStateAlbumsGrabbed];
                                    
                                }
                                
                                
                            } andErrorBlock:^(NSError *error) {
                                
                                NSLog(@" error ! %@", error);
                                
                                if ( allowedRetriesCount > 0 ){
                                    
                                    [self loadAlbumsAtPageIndex:pageIndex withNumberOfAlbumsPerPage:numberOfAlbumsPerPage andNumberOfAllowedRetries:allowedRetriesCount-1];
                                    
                                    return;
                                    
                                } else {
                                
                                    [self setState:GRKPickerAlbumsListStateGrabbingFailed];
                                
                                }
                                
                            }];
    
}



@end
