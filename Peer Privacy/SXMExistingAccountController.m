//
//  SXMViewJabberAccountController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMExistingAccountController.h"
#import "SXMAppDelegate.h"

@interface SXMExistingAccountController ()

@end

@implementation SXMExistingAccountController

@synthesize userId;
@synthesize enabled, rememberPassword;

- (SXMAppDelegate *)appDelegate
{
	return (SXMAppDelegate *)[[UIApplication sharedApplication] delegate];
}


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

- (void)deleteAccount
{
    NSManagedObjectContext *context = [self appDelegate].managedObjectContext;
    self.account = [SXMAccount deleteAndReallocate:self.account inManagedObjectContext:context];
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
