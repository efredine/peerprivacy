//
//  SXMNewJabbberAccountController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMEditJabberAccountController.h"
#import "SXMStreamCoordinator.h"

@implementation SXMEditJabberAccountController

@synthesize delegate;
@synthesize userId, password;
@synthesize enabled, rememberPassword;
@synthesize logInOut;
@synthesize connectActivity;
@synthesize cancelButton;

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
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelected:)];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
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
    
    self.delegate = nil;
    self.userId = nil;
    self.password = nil;
    self.enabled = nil;
    self.rememberPassword = nil;
    self.logInOut = nil;
    self.connectActivity = nil;
    self.cancelButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark Logging In

- (void)doLogIn
{
    self.account.userId = [self.userId.text copy];
    self.account.password = [self.password.text copy];
    self.account.enabled = self.enabled.enabled;
    self.account.rememberPassword = self.rememberPassword.enabled;
    
    SXMStreamCoordinator *streamCoordinator = [SXMStreamCoordinator sharedInstance];
    SXMStreamManager *stream = [streamCoordinator allocateStreamManagerforAccount:self.account];
    
    [self.connectActivity startAnimating];
    self.logInOut.enabled = NO;
    self.cancelButton.enabled = NO;
    [stream connectWithCompletion:^(BOOL connected) {
        [self.connectActivity stopAnimating];
        if (connected) {
            self.account.configured = YES;
            [self.delegate SXMNewJabbberAccountController:self withAccount:self.account];
        }
        else {
            // display an alert telling the user to try again!
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection failed" message:@"Check your user id and password and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert  show];
            self.logInOut.enabled = YES;
            self.cancelButton.enabled = YES;
        }
    }];
}

#pragma UI Actions

- (IBAction)cancelSelected:(id)sender
{
    [self.delegate SXMNewJabbberAccountControllerCancelled:self];
}

-(IBAction)logButton:(id)sender
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
