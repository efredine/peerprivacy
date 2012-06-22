//
//  SXMSimpleConversationStarterController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-21.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SXMSimpleConversationStarterController;
@protocol SXMConversationStarterDelegate <NSObject>

- (void) conversationStarterViewController: (SXMSimpleConversationStarterController *)sender: (BOOL) didChoose;

@end

@interface SXMSimpleConversationStarterController : UIViewController

@property (strong, nonatomic) id<SXMConversationStarterDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextField *yourJidTextField;
@property (strong, nonatomic) IBOutlet UITextField *otherJidTextField;

- (IBAction)okSelected:(id)sender;
- (IBAction)cancelSelected:(id)sender;

@end
