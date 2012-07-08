//
//  SXMDetailViewController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAppDelegate.h"
#import "SXMMessageViewController.h"
#import "XMPPRosterCoreDataStorage.h"
#import "SXMStreamManager.h"
#import "SXMStreamCoordinator.h"
#import <QuartzCore/QuartzCore.h>

#define CHAT_BACKGROUND_COLOR [UIColor colorWithRed:0.859f green:0.886f blue:0.929f alpha:1.0f]

#define VIEW_WIDTH self.view.frame.size.width
#define VIEW_HEIGHT self.view.frame.size.height

#define RESET_CHAT_BAR_HEIGHT SET_CHAT_BAR_HEIGHT(kChatBarHeight1)
#define EXPAND_CHAT_BAR_HEIGHT SET_CHAT_BAR_HEIGHT(kChatBarHeight4)
#define SET_CHAT_BAR_HEIGHT(HEIGHT)\
CGRect chatContentFrame = chatContent.frame;\
chatContentFrame.size.height = VIEW_HEIGHT - HEIGHT;\
[UIView beginAnimations:nil context:NULL];\
[UIView setAnimationDuration:0.1f];\
chatContent.frame = chatContentFrame;\
chatBar.frame = CGRectMake(chatBar.frame.origin.x, chatContentFrame.size.height,\
VIEW_WIDTH, HEIGHT);\
[UIView commitAnimations]

#define BAR_BUTTON(TITLE, SELECTOR) [[UIBarButtonItem alloc] initWithTitle:TITLE\
style:UIBarButtonItemStylePlain target:self action:SELECTOR]

#define ClearConversationButtonIndex 0

// 15 mins between messages before we show the date
#define SECONDS_BETWEEN_MESSAGES (60*15)

static CGFloat const kSentDateFontSize = 13.0f;
static CGFloat const kMessageFontSize = 16.0f; // 15.0f, 14.0f
static CGFloat const kMessageTextWidth = 180.0f;
static CGFloat const kContentHeightMax = 84.0f; // 80.0f, 76.0f
static CGFloat const kChatBarHeight1 = 40.0f;
static CGFloat const kChatBarHeight4 = 94.0f;


@interface SXMMessageViewController ()
@property BOOL viewInitializing;
@property BOOL keyBoardVisible;
@property CGRect keyboardEndFrame;
@end

@implementation SXMMessageViewController

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;

@synthesize conversation;

@synthesize chatContent;

@synthesize chatBar;
@synthesize chatInput;
@synthesize previousContentHeight;
@synthesize sendButton;

@synthesize viewInitializing, keyBoardVisible;
@synthesize keyboardEndFrame;

- (SXMAppDelegate *)appDelegate
{
	return (SXMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"viewDidLoad");
    
    self.viewInitializing = YES;
    
    self.title = conversation.user.displayName;
    
    // Listen for keyboard.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    self.view.backgroundColor = CHAT_BACKGROUND_COLOR; // shown during rotation
    
    // Create chatContent.
    chatContent = [[UITableView alloc] initWithFrame:
                   CGRectMake(0.0f, 0.0f, self.view.frame.size.width,
                              self.view.frame.size.height-kChatBarHeight1)];
    chatContent.clearsContextBeforeDrawing = NO;
    chatContent.delegate = self;
    chatContent.dataSource = self;
    chatContent.contentInset = UIEdgeInsetsMake(7.0f, 0.0f, 0.0f, 0.0f);
    chatContent.backgroundColor = CHAT_BACKGROUND_COLOR;
    chatContent.separatorStyle = UITableViewCellSeparatorStyleNone;
    chatContent.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:chatContent];
    
    // Create chatBar.
    chatBar = [[UIImageView alloc] initWithFrame:
               CGRectMake(0.0f, self.view.frame.size.height-kChatBarHeight1,
                          self.view.frame.size.width, kChatBarHeight1)];
    chatBar.clearsContextBeforeDrawing = NO;
    chatBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleWidth;
    chatBar.image = [[UIImage imageNamed:@"ChatBar.png"]
                     stretchableImageWithLeftCapWidth:18 topCapHeight:20];
    chatBar.userInteractionEnabled = YES;
    
    // Create chatInput.
    chatInput = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 9.0f, 234.0f, 24.0f)];
    chatInput.contentSize = CGSizeMake(234.0f, 22.0f);
    chatInput.delegate = self;
    chatInput.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    chatInput.scrollEnabled = NO; // not initially
    chatInput.scrollIndicatorInsets = UIEdgeInsetsMake(5.0f, 0.0f, 4.0f, -2.0f);
    chatInput.clearsContextBeforeDrawing = NO;
    chatInput.font = [UIFont systemFontOfSize:kMessageFontSize];
    chatInput.dataDetectorTypes = UIDataDetectorTypeAll;
    chatInput.contentMode = UIViewContentModeTop;
//    chatInput.contentOffset = CGPointMake(0.0f, 6.0f);
    chatInput.backgroundColor = [UIColor clearColor];
    
//    [chatInput addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:nil];

    previousContentHeight = chatInput.contentSize.height;

    [chatBar addSubview:chatInput];
    
    // Create sendButton.
    sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.clearsContextBeforeDrawing = NO;
    sendButton.frame = CGRectMake(chatBar.frame.size.width - 70.0f, 8.0f, 64.0f, 26.0f);
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | // multi-line input
    UIViewAutoresizingFlexibleLeftMargin; // landscape
    UIImage *sendButtonBackground = [UIImage imageNamed:@"SendButton.png"];
    [sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateNormal];
    [sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateDisabled];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    UIColor *shadowColor = [[UIColor alloc] initWithRed:0.325f green:0.463f blue:0.675f alpha:1.0f];
    [sendButton setTitleShadowColor:shadowColor forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendMessage)
         forControlEvents:UIControlEventTouchUpInside];
    // // The following three lines aren't necessary now that we'are using background image.
    // sendButton.backgroundColor = [UIColor clearColor];
    // sendButton.layer.cornerRadius = 13;
    // sendButton.clipsToBounds = YES;
    [self resetSendButton]; // disable initially
    [chatBar addSubview:sendButton];
    
    [self.view addSubview:chatBar];
    [self.view sendSubviewToBack:chatBar];
    
    // if there are no messages yet, display the keyboard immediately
    if ([[self.fetchedResultsController sections] count] == 1) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
        if ([sectionInfo numberOfObjects] == 0){
            [self.chatInput becomeFirstResponder];
        }
    }
          
    // // Test with lots of messages.
    // NSDate *before = [NSDate date];
    // for (NSUInteger i = 0; i < 500; i++) {
    // Message *msg = (Message *)[NSEntityDescription
    // insertNewObjectForEntityForName:@"Message"
    // inManagedObjectContext:managedObjectContext];
    // msg.text = [NSString stringWithFormat:@"This is message number %d", i];
    // NSDate *now = [[NSDate alloc] init]; msg.sentDate = now; [now release];
    // }
    //// sleep(2);
    // NSLog(@"Creating messages in memory takes %f seconds", [before timeIntervalSinceNow]);
    // NSError *error;
    // if (![managedObjectContext save:&error]) {
    // // TODO: Handle the error appropriately.
    // NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
    // }
    // NSLog(@"Saving messages to disc takes %f seconds", [before timeIntervalSinceNow]);
    
    NSLog(@"End of view Did Load");
    
}

//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    
//    NSLog(@"contentOffset: %f, %f", chatInput.contentOffset.x, chatInput.contentOffset.y);
//
////    CGFloat contentHeight = chatInput.contentSize.height - kMessageFontSize + 2.0f;
////
////    if ( contentHeight < kContentHeightMax) {
////        chatInput.contentOffset = CGPointMake(0.0f, 6.0f);
////    }    
//}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    self.chatBar = nil;
    [chatInput removeObserver:self forKeyPath:@"contentSize"];
    self.chatInput = nil;
    self.sendButton = nil;
    self.conversation = nil;
    self.fetchedResultsController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; // below: work around for [chatContent flashScrollIndicators]
    NSLog(@"viewWillAppear");
    [chatContent performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
//    [chatInput resignFirstResponder];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    NSLog(@"Will layout subviews");
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    NSLog(@"Did layout subviews");
    NSLog(@"view frame: %@", NSStringFromCGRect(self.view.frame));
    NSLog(@"chatbar frame: %@", NSStringFromCGRect(self.chatBar.frame));
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.viewInitializing && self.keyBoardVisible) {
        CGRect viewFrame = self.view.frame;
        CGRect keyboardFrameEndRelative = [self.view convertRect:keyboardEndFrame fromView:nil];
        viewFrame.size.height = keyboardFrameEndRelative.origin.y;
        self.view.frame = viewFrame;
        [self scrollToBottomAnimated:NO];
    }
    self.viewInitializing = NO;
    NSLog(@"viewDidAppear: %i", animated);
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat contentHeight = textView.contentSize.height - kMessageFontSize + 2.0f;
    NSString *rightTrimmedText = @"";
    
    // NSLog(@"contentOffset: (%f, %f)", textView.contentOffset.x, textView.contentOffset.y);
    // NSLog(@"contentInset: %f, %f, %f, %f", textView.contentInset.top, textView.contentInset.right,
    // textView.contentInset.bottom, textView.contentInset.left);
    // NSLog(@"contentSize.height: %f", contentHeight);
    
    if ([textView hasText]) {
//        rightTrimmedText = [textView.text
//                            stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
        rightTrimmedText = textView.text;
       
        // if (textView.text.length > 1024) { // truncate text to 1024 chars
        // textView.text = [textView.text substringToIndex:1024];
        // }
        
        // Resize textView to contentHeight
        if (contentHeight != previousContentHeight) {
            if (contentHeight <= kContentHeightMax) { // limit chatInputHeight <= 4 lines
                CGFloat chatBarHeight = contentHeight + 18.0f;
                SET_CHAT_BAR_HEIGHT(chatBarHeight);
                if (previousContentHeight > kContentHeightMax) {
                    textView.scrollEnabled = NO;
                }
                textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
                [self scrollToBottomAnimated:YES];
            } else if (previousContentHeight <= kContentHeightMax) { // grow
                textView.scrollEnabled = YES;
                textView.contentOffset = CGPointMake(0.0f, contentHeight-68.0f); // shift to bottom
                if (previousContentHeight < kContentHeightMax) {
                    EXPAND_CHAT_BAR_HEIGHT;
                    [self scrollToBottomAnimated:YES];
                }
            }
        }
    } else { // textView is empty
        if (previousContentHeight > 22.0f) {
            RESET_CHAT_BAR_HEIGHT;
            if (previousContentHeight > kContentHeightMax) {
                textView.scrollEnabled = NO;
            }
        }
//        textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
    }
    
    // Enable sendButton if chatInput has non-blank text, disable otherwise.
    if (rightTrimmedText.length > 0) {
        [self enableSendButton];
    } else {
        [self disableSendButton];
    }
    
    previousContentHeight = contentHeight;
}


 // Fix a scrolling quirk.
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    textView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    return YES;
}

#pragma mark ChatViewController

- (void)enableSendButton {
    if (sendButton.enabled == NO) {
        sendButton.enabled = YES;
        sendButton.titleLabel.alpha = 1.0f;
    }
}

- (void)disableSendButton {
    if (sendButton.enabled == YES) {
        [self resetSendButton];
    }
}

- (void)resetSendButton {
    sendButton.enabled = NO;
    sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
}


# pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    NSLog(@"Keyboard will show");
    if (self.viewInitializing) {
        [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    }
    else {
        [self resizeViewWithOptions:[notification userInfo]];
    }
    self.keyBoardVisible = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSLog(@"Keyboard will hide");
    [self resizeViewWithOptions:[notification userInfo]];
    self.keyBoardVisible = NO;
}

- (void)resizeViewWithOptions:(NSDictionary *)options {
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    [[options objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[options objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[options objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
 
    NSLog(@"animationDuration: %f", animationDuration);
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    CGRect viewFrame = self.view.frame;
    NSLog(@"viewFrame y: %@", NSStringFromCGRect(viewFrame));
    
    // // For testing.
//    NSLog(@"keyboardEnd: %@", NSStringFromCGRect(keyboardEndFrame));
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
//    initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//    target:chatInput action:@selector(resignFirstResponder)];
//    self.navigationItem.leftBarButtonItem = doneButton;
    
    CGRect keyboardFrameEndRelative = [self.view convertRect:keyboardEndFrame fromView:nil];
    NSLog(@"self.view: %@", self.view);
    NSLog(@"keyboardFrameEndRelative: %@", NSStringFromCGRect(keyboardFrameEndRelative));
    
    viewFrame.size.height = keyboardFrameEndRelative.origin.y;
    self.view.frame = viewFrame;
    
    [UIView commitAnimations];
    
    [self scrollToBottomAnimated:YES];
    
    chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];    
    NSInteger numRows = [sectionInfo numberOfObjects];
    if (numRows > 1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numRows-1 inSection:0];
        [chatContent scrollToRowAtIndexPath:indexPath
                           atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

static NSString *kMessageCell = @"MessageCell";
#define SENT_DATE_TAG 101
#define TEXT_TAG 102
#define BACKGROUND_TAG 103


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UIImageView *msgBackground;
    UILabel *msgText;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:kMessageCell];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Create message background image view
        msgBackground = [[UIImageView alloc] init];
        msgBackground.clearsContextBeforeDrawing = NO;
        msgBackground.tag = BACKGROUND_TAG;
        msgBackground.backgroundColor = CHAT_BACKGROUND_COLOR; // clearColor slows performance
        [cell.contentView addSubview:msgBackground];
        
        // Create message text label
        msgText = [[UILabel alloc] init];
        msgText.clearsContextBeforeDrawing = NO;
        msgText.tag = TEXT_TAG;
        msgText.backgroundColor = [UIColor clearColor];
        msgText.numberOfLines = 0;
        msgText.lineBreakMode = UILineBreakModeWordWrap;
        msgText.font = [UIFont systemFontOfSize:kMessageFontSize];
        [cell.contentView addSubview:msgText];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"height for row: %d", [indexPath row]);
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *body = [object valueForKey:@"body"];
    
    // Set MessageCell height.
    CGSize size = [body sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    return size.height + 17.0f;
}



#pragma mark Message Handling

- (void)sendMessage
{
    NSLog(@"Send message");
    
    SXMStreamCoordinator *msm = [[self appDelegate] streamCoordinator];
    SXMStreamManager *streamManager = [msm streamManagerforStreamBareJidStr:conversation.streamBareJidStr];
    [streamManager sendMessageWithBody:self.chatInput.text andJidStr:conversation.jidStr];

    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    SXMMessage *newMessage = [self.conversation insertNewMessageInManagedObjectContext:context];  
    
    newMessage.body = self.chatInput.text;
    newMessage.fromMe = [NSNumber numberWithBool:YES];
    newMessage.read = [NSNumber numberWithBool:YES];
     
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [self clearChatInput];
    [self scrollToBottomAnimated:YES]; // must come after RESET_CHAT_BAR_HEIGHT above
}

- (void)clearChatInput {
    chatInput.text = @"";
    if (previousContentHeight > 22.0f) {
        RESET_CHAT_BAR_HEIGHT;
        chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
        chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
        [self scrollToBottomAnimated:YES];
    }
}



#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SXMMessage" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"conversation == %@", 
                              self.conversation];
    [fetchRequest setPredicate:predicate];

    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"localTimestamp" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.chatContent beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.chatContent insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.chatContent deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.chatContent;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.chatContent endUpdates];
    [self scrollToBottomAnimated:YES];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SXMMessage *message = [self.fetchedResultsController objectAtIndexPath:indexPath];

    BOOL fromMeBool = [message.fromMe boolValue];
    NSString *body = message.body;
    
    UIImageView *msgBackground;
    UILabel *msgText;

    msgBackground = (UIImageView *)[cell.contentView viewWithTag:BACKGROUND_TAG];
    msgText = (UILabel *)[cell.contentView viewWithTag:TEXT_TAG];
    
    // Configure the cell to show the message in a bubble. Layout message cell & its subviews.
    CGSize size = [body sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    UIImage *bubbleImage;
    if (fromMeBool) { // right bubble
        CGFloat editWidth = self.chatContent.editing ? 32.0f : 0.0f;
        msgBackground.frame = CGRectMake(self.chatContent.frame.size.width-size.width-34.0f-editWidth,
                                         kMessageFontSize-13.0f, size.width+34.0f,
                                         size.height+12.0f);
        bubbleImage = [[UIImage imageNamed:@"ChatBubbleGreen.png"]
                       stretchableImageWithLeftCapWidth:15 topCapHeight:13];
        msgText.frame = CGRectMake(self.chatContent.frame.size.width-size.width-22.0f-editWidth,
                                   kMessageFontSize-9.0f, size.width+5.0f, size.height);
        msgBackground.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        msgText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        // // Uncomment for view layout debugging.
        // cell.contentView.backgroundColor = [UIColor blueColor];
    } else { // left bubble
        msgBackground.frame = CGRectMake(0.0f, kMessageFontSize-13.0f,
                                         size.width+34.0f, size.height+12.0f);
        bubbleImage = [[UIImage imageNamed:@"ChatBubbleGray.png"]
                       stretchableImageWithLeftCapWidth:23 topCapHeight:15];
        msgText.frame = CGRectMake(22.0f, kMessageFontSize-9.0f, size.width+5.0f, size.height);
        msgBackground.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        msgText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }
    msgBackground.image = bubbleImage;
    msgText.text = body;
    
}

@end
