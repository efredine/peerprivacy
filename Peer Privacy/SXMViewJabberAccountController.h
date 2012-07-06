//
//  SXMViewJabberAccountController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAccountDetailViewController.h"

@interface SXMViewJabberAccountController : SXMAccountDetailViewController
@property (strong, nonatomic) IBOutlet UILabel *userId;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UISwitch *enabled;
@property (strong, nonatomic) IBOutlet UISwitch *rememberPassword;

- (IBAction)logOut:(id)sender;
- (IBAction)deleteButton:(id)sender;

@end
