//
//  SXMViewJabberAccountController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMViewJabberAccountController.h"

@interface SXMViewJabberAccountController ()

@end

@implementation SXMViewJabberAccountController

@synthesize userId;
@synthesize password;
@synthesize enabled, rememberPassword;

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark buttons

- (IBAction)logOut:(id)sender
{
    
}

- (IBAction)deleteButton:(id)sender
{
    
}


@end
