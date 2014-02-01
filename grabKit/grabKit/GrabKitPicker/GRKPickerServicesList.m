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

#import "GrabKit.h"
#import "GRKPickerViewController.h"
#import "GRKPickerViewController+privateMethods.h"
#import "GRKPickerServicesList.h"
#import "GRKPickerAlbumsList.h"


@implementation GRKPickerServicesList


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
                
    }
    return self;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self ){
        
        // build the array of services
        services = [NSMutableArray array];
        
        
        // build a dictionary per service
        #if GRK_FACEBOOK_SERVICE
        NSDictionary * facebook = [NSDictionary dictionaryWithObjectsAndKeys:@"GRKFacebookGrabber", @"class",
                                   @"Facebook", @"title", @"facebook.png", @"images",
                                   nil];
        [services addObject:facebook];
        #endif
        
        #if GRK_FLICKR_SERVICE
        NSDictionary * flickr = [NSDictionary dictionaryWithObjectsAndKeys:@"GRKFlickrGrabber", @"class", 
                                 @"FlickR", @"title", @"flickr.png", @"images",
                                 nil];
        [services addObject:flickr];
        #endif
        
        #if GRK_INSTAGRAM_SERVICE
        NSDictionary * instagram = [NSDictionary dictionaryWithObjectsAndKeys:@"GRKInstagramGrabber", @"class", 
                                    @"Instagram", @"title", @"instagram.png", @"images",
                                    nil];
        [services addObject:instagram];
        #endif
        
        #if GRK_PICASA_SERVICE
        NSDictionary * picasa = [NSDictionary dictionaryWithObjectsAndKeys:@"GRKPicasaGrabber", @"class", 
                                 @"Picasa", @"title", @"picasa.png", @"images",
                                 nil];
        [services addObject:picasa];
        #endif
        
//        #if GRK_DEVICE_SERVICE
//        NSDictionary * device = [NSDictionary dictionaryWithObjectsAndKeys:@"GRKDeviceGrabber", @"class", 
//                                 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)?@"iPad":@"iPhone", @"title",
//                                 nil];
//        [services addObject:device];
//        #endif
        

        //services = [[NSArray alloc] initWithObjects:facebook, flickr, instagram, picasa, device, nil];
        
        
    }
    
    return self;    
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
    
    self.navigationItem.title = GRK_i18n(@"GRK_SERVICES_LIST_TITLE", @"Network");

    self.tableView.rowHeight = 56;
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:218.0f/255.0f green:86.0f/255.0f blue:42.0f/255.0f alpha:1.0f];
    
    self.tableView.separatorColor = [UIColor colorWithRed:218.0f/255.0f green:218.0f/255.0f blue:218.0f/255.0f alpha:1.0f];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithRed:241.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0f];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTouchCancelButton)];
 
}


-(void) didTouchCancelButton {
    
    [[GRKPickerViewController sharedInstance] dismiss];
}

#pragma mark View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIEdgeInsets inset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.contentInset = inset;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [services count];
    else
        return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        tableView.tableHeaderView.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"network-header.png"]];
        return @"Cihaz";
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    if (section == 1) {
        UIImage *myImage = [UIImage imageNamed:@"network-header.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage];
        return imageView;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return 33;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0)
        return 20;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
        static NSString *CellIdentifier = @"Cell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        NSString * serviceName = [(NSDictionary *)[services objectAtIndex:indexPath.row] objectForKey:@"title"];
        cell.textLabel.text = serviceName;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ Resimlerini Kullan", serviceName];
        
        NSString * iconName = [(NSDictionary *)[services objectAtIndex:indexPath.row] objectForKey:@"images"];
        cell.imageView.image = [UIImage imageNamed:iconName];
        
        return cell;
    }else
    {
        if (indexPath.row == 0) {
            static NSString *CellIdentifier = @"Cell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            }
            
            cell.textLabel.text = @"Iphone Resimleri";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.detailTextLabel.text = @"Iphone Resimlerini Kullan";
            
            //        NSString * iconName = [(NSDictionary *)[services objectAtIndex:indexPath.row] objectForKey:@"images"];
            cell.imageView.image = [UIImage imageNamed:@"social-picker.png"];
            
            return cell;
        }else
        {
            static NSString *CellIdentifier = @"Cell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            }
            
            cell.textLabel.text = @"Resim Cek";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.detailTextLabel.text = @"Yeni Bir Resim Cek";
            
            //        NSString * iconName = [(NSDictionary *)[services objectAtIndex:indexPath.row] objectForKey:@"images"];
            cell.imageView.image = [UIImage imageNamed:@"social-camera.png"];
            
            return cell;
        }
        
    }
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.textColor = [UIColor colorWithRed:73.0f/255.0f green:73.0f/255.0f blue:75.0f/255.0f alpha:1.0f];
    cell.textLabel.font = [UIFont fontWithName:@"DINCondensed-Bold" size:15];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:176.0f/255.0f green:176.0f/255.0f blue:176.0f/255.0f alpha:1.0f];
    cell.detailTextLabel.font = [UIFont fontWithName:@"DINCondensed-Bold" size:12];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString * grabberClassName = [[services objectAtIndex:indexPath.row] objectForKey:@"class"];
    NSString * grabberServiceName = [[services objectAtIndex:indexPath.row] objectForKey:@"title"];
    
    
    Class grabberClass = NSClassFromString(grabberClassName);
    
    id grabber = nil;
    @try {
        grabber = [[grabberClass alloc] init];
    }
    @catch (NSException *exception) {

        NSLog(@" exception : %@", exception);
    }

    
    if ( grabber == nil ){
        
        
        NSString * grabberNotAvailableMessage = [NSString stringWithFormat:@"The grabber class %@ doesn't exist.", grabberClassName];
        UIAlertView * grabberNotAvailableAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:grabberNotAvailableMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] ;
        
        [grabberNotAvailableAlertView show];
        
        return;
    }
    
    
    GRKPickerAlbumsList * albumsList = [[GRKPickerAlbumsList alloc] initWithGrabber:grabber andServiceName:grabberServiceName];
    [self.navigationController pushViewController:albumsList animated:YES];
    
    
}

@end
