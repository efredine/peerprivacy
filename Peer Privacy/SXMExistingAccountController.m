//
//  SXMViewJabberAccountController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMExistingAccountController.h"
#import "SXMAppDelegate.h"
#import "SXMRosterCoreDataStorage.h"
#import "SXMStreamCoordinator.h"
#import "SXMStreamManager.h"
#import "SXMRosterCoreDataStorage.h"

@interface SXMExistingAccountController ()

@end

@implementation SXMExistingAccountController

@synthesize userId;
@synthesize enabled, rememberPassword;

#pragma helpers

- (SXMAppDelegate *)appDelegate
{
	return (SXMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [[SXMRosterCoreDataStorage sharedInstance] mainThreadManagedObjectContext];
}

#pragma view

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationItem.title = self.account.name;
    self.userId.text = self.account.userId;
    self.enabled.enabled = self.account.enabled;
    self.rememberPassword.enabled = self.account.rememberPassword;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark account deletion

- (void)deleteAccountRoster
{
    [[SXMRosterCoreDataStorage sharedInstance] deleteRosterforStreamBareJidStr:self.account.streamBareJidStr];
}

- (void)deleteAccount
{
    // disconnect the stream
    SXMStreamManager *streamManager = [[SXMStreamCoordinator sharedInstance] streamManagerforAccount:self.account];
    [streamManager disconnect];
    
    // find and delete roster entries
    [self deleteAccountRoster];
     
    // delete the account
    NSManagedObjectContext *context = [self appDelegate].managedObjectContext;
    self.account = [SXMAccount deleteAndReallocate:self.account inManagedObjectContext:context];
    [[self appDelegate] saveContext];
    
    // pop the view
    UINavigationController *myNavigationContoller = (UINavigationController *)self.parentViewController;
    [myNavigationContoller popViewControllerAnimated:YES];
}

#pragma mark buttons

- (IBAction)logButton:(id)sender
{
    
}

- (IBAction)deleteButton:(id)sender
{
    // TODO: add an alert to double check.
    
    [self deleteAccount];
    
}


@end
