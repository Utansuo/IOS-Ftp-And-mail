//
//  FtpCheckDir.m
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-2.
//
//

#import "FtpCheckDir.h"

#import "exClassHandler.h"
#import "FtpUploadFile.h"
#import "FtpCreateDir.h"

static FtpCheckDir* ftpCheckDir = nil;

@implementation FtpCheckDir

@synthesize nsArray = _nsArray;
@synthesize  fileList = _fileList;


+(FtpCheckDir*)FtpCheckDirSingleton
{
   if(ftpCheckDir == nil)
   {
       ftpCheckDir = [[FtpCheckDir alloc]init];
       [ftpCheckDir initFunc];
   }
    return  ftpCheckDir;
}

-(void)initFunc
{
    self.nsArray = [[NSArray alloc]init];
    [ftpCheckDir startReceive];
}


- (void)updateStatus:(NSString *)statusString
{
    
}

-(BOOL)CheckFileName:(NSString*)dirName{
    _nsArray = [  self.fileList  componentsSeparatedByString:@"@"];
    for(int i=0;i<[ _nsArray count];i++)
    {
        NSString* fileName = [ _nsArray objectAtIndex:i];
        if([fileName isEqualToString:dirName])
        {
            return true;
        }
    }
    return  false;
}

- (void)receiveDidStopWithStatus:(NSString *)statusString
{
    if(statusString == nil)
    {
       if( [self CheckFileName:[[exClassHandler ShareExClassHandle] dirName]])
       {
           [FtpUploadFile FtpUpLoadSingleton];
       }
        else
        {
            [FtpCreateDir FtpCreateDirSingleton];
        }
    }
    else
    {
       if([[exClassHandler ShareExClassHandle]runLoopFlag])
       {
           [[exClassHandler ShareExClassHandle]setRunLoopFlag:NO];
           [[exClassHandler ShareExClassHandle]exitThread];
       }
    }
    [self.fileList autorelease];
}


- (void)startReceive
// Starts a connection to download the current URL.
{
    BOOL                success;
    NSURL *             url;
    
    self.fileList = [[NSString alloc]init];
    assert(self.networkStream == nil);      // don't tap receive twice in a row!
    
    // First get and check the URL.
 
    url = [[exClassHandler ShareExClassHandle] smartURLForString:[[exClassHandler ShareExClassHandle] ftpUrl]];
    success = (url != nil);
    
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
        
        // Create the mutable data into which we will receive the listing.
        self.listData = [NSMutableData data];
        assert(self.listData != nil);
    
        // Open a CFFTPStream for the URL.
         NSLog(@"aaaaa=%@ ",[[exClassHandler ShareExClassHandle] userName] );
        self.networkStream = (NSInputStream*)CFReadStreamCreateWithFTPURL(NULL, (CFURLRef) url);
        assert(self.networkStream != nil);
        success = [self.networkStream setProperty:[[exClassHandler ShareExClassHandle] userName] forKey:(id)kCFStreamPropertyFTPUserName];
        assert(success);
        success = [self.networkStream setProperty:[[exClassHandler ShareExClassHandle] password] forKey:(id)kCFStreamPropertyFTPPassword];
        assert(success);

        self.networkStream.delegate = self;
        [self.networkStream scheduleInRunLoop:[[exClassHandler ShareExClassHandle] runLoop] forMode:NSRunLoopCommonModes];
        [self.networkStream open];
        
        // Tell the UI we're receiving.
}

- (void)stopReceiveWithStatus:(NSString *)statusString
// Shuts down the connection and displays the result (statusString == nil)
// or the error status (otherwise).
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[[exClassHandler ShareExClassHandle] runLoop] forMode:NSRunLoopCommonModes];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    [self receiveDidStopWithStatus:statusString];
}

- (void)entryByReencodingNameInEntry:(NSDictionary *)entry
// CFFTPCreateParsedResourceListing always interprets the file name as MacRoman,
// which is clearly bogus <rdar://problem/7420589>.  This code attempts to fix
// that by converting the Unicode name back to MacRoman (to get the original bytes;
// this works because there's a lossless round trip between MacRoman and Unicode)
// and then reconverting those bytes to Unicode using the encoding provided.
{
    NSString *      name;

    // Try to get the name, convert it back to MacRoman, and then reconvert it
    // with the preferred encoding.
    
    name = [entry objectForKey:(id) kCFFTPResourceName];
      self.fileList = [ self.fileList  stringByAppendingString:@"@"];
      self.fileList =  [ self.fileList  stringByAppendingString:name];
    NSLog(@" dir name =%@",name);
}

- (void)parseListData
{
    NSUInteger          offset;
    
    // We accumulate the new entries into an array to avoid a) adding items to the
    // table one-by-one, and b) repeatedly shuffling the listData buffer around.

    
    offset = 0;
    do {
        CFIndex         bytesConsumed;
        CFDictionaryRef thisEntry;
        
        thisEntry = NULL;
        
        assert(offset <= [self.listData length]);
        bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) self.listData.bytes)[offset], (CFIndex) ([self.listData length] - offset), &thisEntry);
        if (bytesConsumed > 0) {
            
            // It is possible for CFFTPCreateParsedResourceListing to return a
            // positive number but not create a parse dictionary.  For example,
            // if the end of the listing text contains stuff that can't be parsed,
            // CFFTPCreateParsedResourceListing returns a positive number (to tell
            // the caller that it has consumed the data), but doesn't create a parse
            // dictionary (because it couldn't make sense of the data).  So, it's
            // important that we check for NULL.
            
            if (thisEntry != NULL) {
                
                // Try to interpret the name as UTF-8, which makes things work properly
                // with many UNIX-like systems, including the Mac OS X built-in FTP
                // server.  If you have some idea what type of text your target system
                // is going to return, you could tweak this encoding.  For example,
                // if you know that the target system is running Windows, then
                // NSWindowsCP1252StringEncoding would be a good choice here.
                //
                // Alternatively you could let the user choose the encoding up
                // front, or reencode the listing after they've seen it and decided
                // it's wrong.
                //
                // Ain't FTP a wonderful protocol!
                
                [self entryByReencodingNameInEntry:( NSDictionary *) thisEntry];
            }
            
            // We consume the bytes regardless of whether we get an entry.
            
            offset += (NSUInteger) bytesConsumed;
        }
        
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0) {
            // We haven't yet got enough data to parse an entry.  Wait for more data
            // to arrive.
            break;
        } else if (bytesConsumed < 0) {
            // We totally failed to parse the listing.  Fail.
            [self stopReceiveWithStatus:@"Listing parse failed"];
            break;
        }
    } while (YES);
    
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
#pragma unused(aStream)
    assert(aStream == self.networkStream);
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];
            
            [self updateStatus:@"Receiving"];
            
            // Pull some data off the network.
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead < 0) {
                [self stopReceiveWithStatus:@"Network read error"];
            } else if (bytesRead == 0) {
                [self stopReceiveWithStatus:nil];
            } else {
                assert(self.listData != nil);
                
                // Append the data to our listing buffer.
                
                [self.listData appendBytes:buffer length:(NSUInteger) bytesRead];
                
                // Check the listing buffer for any complete entries and update
                // the UI if we find any.
                [self parseListData];
            
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopReceiveWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

-(void)dealloc{
    [super dealloc];
    [_nsArray release];
    [self.listData release];
}


@end
