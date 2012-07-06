//
//  SXMNewJabbberAccountController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMNewJabberAccountController.h"
#import "SXMStreamCoordinator.h"

@implementation SXMNewJabberAccountController

@synthesize delegate;
@synthesize userId, password;
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
    // Cancel button to dismiss this view
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelected:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [self.password setDelegate:self];
    [self.password addTarget:self
                       action:@selector(passwordFieldFinished:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [self.userId setDelegate:self];
    [self.userId addTarget:self
                      action:@selector(userIdFieldFinished:)
            forControlEvents:UIControlEventEditingDidEndOnExit];

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

#pragma mark new account delegate


#pragma mark Logging In

- (void)doLogIn
{
    self.account.userId = [self.userId.text copy];
    self.account.password = [self.password.text copy];
    self.account.enabled = self.enabled.enabled;
    self.account.rememberPassword = self.rememberPassword.enabled;
    
    SXMStreamCoordinator *streamCoordinator = [SXMStreamCoordinator sharedInstance];
    SXMStreamManager *stream = [streamCoordinator allocateStreamManagerforAccount:self.account];
    [stream connect];
  
    self.account.configured = YES;
    
    [self.delegate SXMNewJabbberAccountController:self withAccount:self.account];
}

#pragma UI Actions

- (IBAction)cancelSelected:(id)sender
{
    [self.delegate SXMNewJabbberAccountControllerCancelled:self];
}

-(IBAction)logIn:(id)sender
{
    [self doLogIn];
}

- (IBAction)backgroundTouched:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)passwordFieldFinished:(id)sender
{
    [self doLogIn];
}

- (IBAction)userIdFieldFinished:(id)sender
{
    [self.userId resignFirstResponder];
    [self.password becomeFirstResponder];
}



@end
