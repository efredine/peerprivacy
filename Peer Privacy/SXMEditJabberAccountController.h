//
//  SXMNewJabbberAccountController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAccountDetailViewController.h"

@class SXMEditJabberAccountController;

@protocol SXMNewJabbberAccountControllerDelegate <NSObject>
- (void) SXMNewJabbberAccountController:(SXMEditJabberAccountController *)sender withAccount: (SXMAccount *)account;
- (void) SXMNewJabbberAccountControllerCancelled:(SXMEditJabberAccountController *)sender;
@end

@interface SXMEditJabberAccountController : SXMAccountDetailViewController <UITextFieldDelegate>

@property (strong, nonatomic) id<SXMNewJabbberAccountControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *userId;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UISwitch *enabled;
@property (strong, nonatomic) IBOutlet UISwitch *rememberPassword;

- (IBAction)logButton:(id)sender;
- (IBAction)backgroundTouched:(id)sender;

@end


