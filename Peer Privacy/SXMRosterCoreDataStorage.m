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

@implementation SXMRosterCoreDataStorage

@synthesize pendingElements;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utility Methods
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

- (void) addItemToRoster: (NSXMLElement *)item  forStream: (XMPPStream *) stream inManagedObjectContext: (NSManagedObjectContext *) moc
{
    NSString *streamBareJidStr = [[self myJIDForXMPPStream:stream] bare];
    
    [XMPPUserCoreDataStorageObject insertInManagedObjectContext:moc
                                                       withItem:item
                                               streamBareJidStr:streamBareJidStr];

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
        [self clearRosterforStream: stream];
        
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
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSMutableArray *streamPendingElements = [self.pendingElements objectForKey:streamKey];
        for (NSXMLElement *item in streamPendingElements) {
            [self addItemToRoster:item forStream:stream inManagedObjectContext:moc];
        }
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
	XMPPLogTrace();
	
	[self scheduleBlock:^{
		
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
		
		NSUInteger unsavedCount = [self numberOfUnsavedChanges];
		
		for (XMPPUserCoreDataStorageObject *user in allUsers)
		{
			[moc deleteObject:user];
			
			if (++unsavedCount >= saveThreshold)
			{
				[self save];
				unsavedCount = 0;
			}
		}
        
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
