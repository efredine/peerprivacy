//
//  SXMNewJabbberAccountController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAccountDetailViewController.h"

@class SXMNewJabberAccountController;

@protocol SXMNewJabbberAccountControllerDelegate <NSObject>
- (void) SXMNewJabbberAccountController:(SXMNewJabberAccountController *)sender withAccount: (SXMAccount *)account;
- (void) SXMNewJabbberAccountControllerCancelled:(SXMNewJabberAccountController *)sender;
@end

@interface SXMNewJabberAccountController : SXMAccountDetailViewController <UITextFieldDelegate>

@property (strong, nonatomic) id<SXMNewJabbberAccountControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *userId;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UISwitch *enabled;
@property (strong, nonatomic) IBOutlet UISwitch *rememberPassword;

- (IBAction)logIn:(id)sender;
- (IBAction)backgroundTouched:(id)sender;

@end


