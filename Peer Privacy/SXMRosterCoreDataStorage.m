//
//  SXMRosterCoreDataStorage.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-08-01.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMRosterCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"
#import "NSNumber+XMPP.h"
#import "XMPPLogging.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_INFO; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation SXMRosterCoreDataStorage

@synthesize pendingElements;

SXMRosterCoreDataStorage *sharedInstance;

+ (SXMRosterCoreDataStorage *)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sharedInstance = [[SXMRosterCoreDataStorage alloc] initWithDatabaseFilename:nil];
	});
	
	return sharedInstance;
}

- (NSString *)managedObjectModelName
{
	// Override me, if needed, to provide customized behavior.
	// 
	// This method is queried to get the name of the ManagedObjectModel within the app bundle.
	// It should return the name of the appropriate file (*.xdatamodel / *.mom / *.momd) sans file extension.
	// 
	// The default implementation returns the name of the subclass, stripping any suffix of "CoreDataStorage".
	// E.g., if your subclass was named "XMPPExtensionCoreDataStorage", then this method would return "XMPPExtension".
	// 
	// Note that a file extension should NOT be included.
    
    return @"XMPPRoster";
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Helper Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) clearRosterforStream :(XMPPStream *)stream
{
    // Clear anything already in the roster core data store.
    // 
    // Note: Deleting a user will delete all associated resources
    // because of the cascade rule in our core data model.
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                              inManagedObjectContext:moc];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:saveThreshold];
    
    if (stream)
    {
        NSPredicate *predicate;
        predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@",
                     [[self myJIDForXMPPStream:stream] bare]];
        
        [fetchRequest setPredicate:predicate];
    }
    
    NSArray *allUsers = [moc executeFetchRequest:fetchRequest error:nil];
    
    for (XMPPUserCoreDataStorageObject *user in allUsers)
    {
        [moc deleteObject:user];
    }
    
    [XMPPGroupCoreDataStorageObject clearEmptyGroupsInManagedObjectContext:moc];
}

- (void) addItemToRoster: (NSXMLElement *)item  forStream: (XMPPStream *) stream 
{
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
    
    [XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
                                                       withItem:item
                                               streamBareJidStr:streamBareJidStr];

}

- (NSArray *) existingUsers
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                              inManagedObjectContext:moc];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"jidStr" ascending:YES selector:@selector(compare:)];
    
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setFetchBatchSize:saveThreshold];
    
    return [moc executeFetchRequest:fetchRequest error:nil];

}

- (NSString *)jidStrFromItem: (NSXMLElement *) item
{
   return [item attributeStringValueForName:@"jid"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Pending Elements Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)pendingElements
{
    if (pendingElements == NULL) {
        pendingElements = [[NSMutableDictionary alloc] init];
    }
    return pendingElements;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Overriden Roster Population methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
    	
	[self scheduleBlock:^{
        [rosterPopulationSet addObject:[NSNumber numberWithPtr:(__bridge void *)stream]];
//        [self clearRosterforStream: stream];
        
        NSMutableArray *streamPendingElements = [[NSMutableArray alloc] init];
        [self.pendingElements setObject:streamPendingElements forKey:[NSNumber numberWithPtr:(__bridge void *)stream]];		
	}];
}

- (void)endRosterPopulationForXMPPStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		NSNumber *streamKey = [NSNumber numberWithPtr:(__bridge void *)stream];
		[rosterPopulationSet removeObject:streamKey];
        
        NSMutableArray *streamPendingElements = [self.pendingElements objectForKey:streamKey];
    
        // Sort the pending elements by bare jid
        [streamPendingElements sortUsingComparator:^NSComparisonResult(NSXMLElement *obj1, NSXMLElement *obj2) {        
            NSString *jid1 = [self jidStrFromItem:obj1];
            NSString *jid2 = [self jidStrFromItem:obj2];
            return [jid1 compare:jid2];
        }];
        
        // Fetch the existing users
        NSArray *existingUsers = [self existingUsers];
        
        // Iterate over the two arrays finding additions and deletions
        int newIndex = 0;
        int existingIndex = 0;
        NSMutableArray *additions = [[NSMutableArray alloc] init];
        NSMutableArray *deletions = [[NSMutableArray alloc] init];
        
        while (newIndex < [streamPendingElements count] && existingIndex < [existingUsers count]) {
            DDLogVerbose(@"Comparing %i to %i", newIndex, existingIndex);
            NSXMLElement *item = [streamPendingElements objectAtIndex:newIndex];
            XMPPUserCoreDataStorageObject *user = [existingUsers objectAtIndex:existingIndex];
            NSString *newJid = [self jidStrFromItem: item];
            NSString *existingJid = user.jidStr;
            switch ([ newJid compare:existingJid])
            {
                case NSOrderedSame:
                    // compare the rest to see if they are really the same or if the element should be updated
                    DDLogVerbose(@"Same.");
                    newIndex++;
                    existingIndex++;
                    break;
                    
                case NSOrderedAscending:
                    // the new element needs to be added
                    DDLogVerbose(@"Adding: %@", item);
                    [additions addObject:item];
                    newIndex++;
                    break;
                    
                case NSOrderedDescending:
                    // the existing user no longer exists in the roster and should be deleted
                    DDLogVerbose(@"Deleting: %@", user);
                    [deletions addObject:user];
                    existingIndex++;
                    break;
                    
                default:
                    break;
            }
        }
    
        // If there are new users remaining, add them.
        for (int i=newIndex; i<[streamPendingElements count]; i++) {
            [additions addObject:[streamPendingElements objectAtIndex:i]];
        }
        
        // If there are existing users remaining, delete them.
        for (int i=existingIndex; i<[existingUsers count]; i++) {
            XMPPUserCoreDataStorageObject *user = [existingUsers objectAtIndex:i];
            [deletions addObject: user];
        }
        
        // Process the additions
        for (NSXMLElement *item in additions) {
            [self addItemToRoster:item forStream:stream];
        }
        
        // Process the deletions
        
        // Done with this stream
        [self.pendingElements removeObjectForKey:streamKey];
	}];
}

- (void)handleRosterItem:(NSXMLElement *)itemSubElement xmppStream:(XMPPStream *)stream
{
	XMPPLogTrace();
	
	// Remember XML heirarchy memory management rules.
	// The passed parameter is a subnode of the IQ, and we need to pass it to an asynchronous operation.
	NSXMLElement *item = [itemSubElement copy];
	
	[self scheduleBlock:^{
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		
		if ([rosterPopulationSet containsObject:[NSNumber numberWithPtr:(__bridge void *)stream]])
		{
            NSNumber *streamKey = [NSNumber numberWithPtr:(__bridge void *)stream];
            NSMutableArray *streamPendingElements = [self.pendingElements objectForKey:streamKey];
           [streamPendingElements addObject:item];
		}
		else
		{
			NSString *jidStr = [item attributeStringValueForName:@"jid"];
			XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
			
			XMPPUserCoreDataStorageObject *user = [self userForJID:jid xmppStream:stream managedObjectContext:moc];
			
			NSString *subscription = [item attributeStringValueForName:@"subscription"];
			if ([subscription isEqualToString:@"remove"])
			{
				if (user)
				{
					[moc deleteObject:user];
				}
			}
			else
			{
				if (user)
				{
					[user updateWithItem:item];
				}
				else
				{
					NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
					
					[XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
					                                                   withItem:item
					                                           streamBareJidStr:streamBareJidStr];
				}
			}
		}
	}];
}

- (void)clearAllUsersAndResourcesForXMPPStream:(XMPPStream *)stream
{
    
    return;
    
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
		// Note: Deleting a user will delete all associated resources
		// because of the cascade rule in our core data model.
		
		NSManagedObjectContext *moc = [self managedObjectContext];
		
//		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
//												  inManagedObjectContext:moc];
//		
//		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//		[fetchRequest setEntity:entity];
//		[fetchRequest setFetchBatchSize:saveThreshold];
//		
//		if (stream)
//		{
//			NSPredicate *predicate;
//			predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@",
//                         [[self myJIDForXMPPStream:stream] bare]];
//			
//			[fetchRequest setPredicate:predicate];
//		}
//		
//		NSArray *allUsers = [moc executeFetchRequest:fetchRequest error:nil];
//		
//		NSUInteger unsavedCount = [self numberOfUnsavedChanges];
//		
//		for (XMPPUserCoreDataStorageObject *user in allUsers)
//		{
//			[moc deleteObject:user];
//			
//			if (++unsavedCount >= saveThreshold)
//			{
//				[self save];
//				unsavedCount = 0;
//			}
//		}
        
		[XMPPGroupCoreDataStorageObject clearEmptyGroupsInManagedObjectContext:moc];
	}];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Other Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)willCreatePersistentStore:(NSString *)filePath
{
	// This method is overriden from the XMPPCoreDataStore superclass.
	// From the documentation:
	// 
	// Override me, if needed, to provide customized behavior.
	// 
	// For example, if you are using the database for pure non-persistent data you may want to delete the database
	// file if it already exists on disk.
	// 
	// The default implementation does nothing.
    //
    // XMPPCoreRosterDataStorage overrides this message and deletes the existing file if it exists.
    // It is overriden here to undo this behavior.  That is - back to doing nothing!
	
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
	}
}

@end
