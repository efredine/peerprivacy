//
//  SXMSimpleConversationStarterController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-21.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMSimpleConversationStarterController.h"


@interface SXMSimpleConversationStarterController ()

@end

@implementation SXMSimpleConversationStarterController

@synthesize delegate;
@synthesize yourJidTextField;
@synthesize otherJidTextField;

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

- (IBAction)okSelected:(id)sender
{
    NSLog(@"OK pressed.");
    
    [self.delegate conversationStarterViewController:self :YES];
}

- (IBAction)cancelSelected:(id)sender
{
    NSLog(@"Cancel pressed.");
    [self.delegate conversationStarterViewController:self :NO];
}


@end
