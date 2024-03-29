//
//  SXMAppDelegate.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAppDelegate.h"

#import "SXMConversationViewController.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#import <CFNetwork/CFNetwork.h>

#import "SXMAccount.h"
#import "SXMStreamManager.h"
#import "SXMFacebookStreamManager.h"
#import "SXMAccount.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define kConversationControllerIndex 0
#define kSettingsControllerIndex 1

@interface SXMAppDelegate()
@property  __block UIBackgroundTaskIdentifier taskId;
@property BOOL pendBackgroundTask;
@end

@implementation SXMAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize streamCoordinator;
@synthesize tabBarController;
@synthesize taskId;
@synthesize pendBackgroundTask;

- (void)bootStrap
{
    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"accountdefaults"
                                              withExtension:@"plist"];
    
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfURL:plistURL];
    NSArray *accountDefaults = [dict objectForKey:@"Accounts"];
    
    for (NSDictionary *item in accountDefaults) {
        SXMAccount *account = [NSEntityDescription 
                               insertNewObjectForEntityForName:@"SXMAccount" 
                               inManagedObjectContext:self.managedObjectContext];
        account.accountType = [[item objectForKey:@"accountType"] integerValue];
        account.configured = NO;
        account.enabled = YES;
        account.name = [item objectForKey:@"name"];
        account.rememberPassword = YES;
    }
    
    [self saveContext];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // Set up the logger
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    NSLog(@"Starting application");
#if DEBUG
    NSLog(@"Debugging is on.");
#endif
    
    DDLogVerbose(@"Test DDLogVerbose!");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"bootStrap"]) {
        [self bootStrap];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"bootStrap"];
        [defaults synchronize];
    }
    
   
    // Override point for customization after application launch.
//    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
//    SXMConversationViewController *controller = (SXMConversationViewController *)navigationController.topViewController;
//    controller.managedObjectContext = self.managedObjectContext;
    
    self.tabBarController = (UITabBarController *)self.window.rootViewController;
    self.tabBarController.delegate = self;
    
//    IASKAppSettingsViewController *settingsController = (IASKAppSettingsViewController *) [self.tabBarController.viewControllers objectAtIndex:kTabBarControllerIndex];
//    settingsController.delegate = self;

    NSUInteger activeAccounts = [SXMAccount numberOfActiveAccountsInManagedContext:self.managedObjectContext];
    if ( activeAccounts == 0 ) {
        UIViewController *settingsController = [self.tabBarController.viewControllers objectAtIndex:kSettingsControllerIndex];
        self.tabBarController.selectedViewController = settingsController;
    }
    
    // The XMPP streams
    self.streamCoordinator = [SXMStreamCoordinator sharedInstance];
    
    return YES;
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
#if TARGET_IPHONE_SIMULATOR
	DDLogError(@"The iPhone simulator does not process background network traffic. "
			   @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
	if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)]) 
	{
 		BOOL result = [application setKeepAliveTimeout:600 handler:^{
			
			DDLogVerbose(@"KeepAliveHandler");
			
			// Do other keep alive stuff here.
		}];
        DDLogVerbose(@"Setting keep alive handler: %d", result);

	}

    // This extends the 'background time' for a while.
//   taskId = [application beginBackgroundTaskWithExpirationHandler:^{
//        NSLog(@"Background task ran out of time and was terminated.");
//        [streamCoordinator releaseAll];
//        [application endBackgroundTask:taskId];
//    }];
//    
//    if (taskId == UIBackgroundTaskInvalid) {
//        NSLog(@"Failed to start background task!");
//        return;
//    }
//    else {
//        pendBackgroundTask = YES;
//    }

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    if (self.pendBackgroundTask) {
//        [application endBackgroundTask:taskId];
//    }
    [streamCoordinator configureStreams];
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [streamCoordinator releaseAll];
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Peer_Privacy" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Peer_Privacy.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Facebook log-in handshake message 

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
    SXMStreamManager *facebookStreamManager = [self.streamCoordinator streamManagerforAccountType:kFacebookAccountType];
    
    return [[facebookStreamManager valueForKey:@"facebook"] handleOpenURL:url];
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
   	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
    SXMStreamManager *facebookStreamManager = [self.streamCoordinator streamManagerforAccountType:kFacebookAccountType];
    return [[facebookStreamManager valueForKey:@"facebook"] handleOpenURL:url];

}

#pragma mark IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    NSLog(@"Settings view ended.");
}

#pragma mark UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if (viewController == [self.tabBarController.viewControllers objectAtIndex:kConversationControllerIndex]) {
        [self.streamCoordinator configureStreams];
    }
}

#pragma mark local notifications
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
