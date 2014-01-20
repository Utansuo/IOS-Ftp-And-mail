//
//  FtpUploadFile.m
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-2.
//
//

#import "FtpUploadFile.h"
#import "exClassHandler.h"

static FtpUploadFile* ftpUpLoad= nil;
@implementation FtpUploadFile

@synthesize networkStream = _networkStream;
@synthesize fileStream = _fileStream;
@synthesize bufferOffset = _bufferOffset;
@synthesize bufferLimit = _bufferLimit;


+(FtpUploadFile*)FtpUpLoadSingleton
{
   if(ftpUpLoad == nil)
   {
       ftpUpLoad = [[FtpUploadFile alloc]init];
       [ftpUpLoad initFunc];
   }
    return ftpUpLoad;
}

-(void)initFunc{
    fileIndex = 0;
    fm = [NSFileManager defaultManager];
    crashFileArray = [[NSArray alloc] initWithArray:[fm contentsOfDirectoryAtPath:[[exClassHandler ShareExClassHandle] exceptFilePath] error:NULL]];
    [ftpUpLoad upLoadFile];
}

-(void)upLoadFile
{
    if([crashFileArray count]<=0)
    {
        return ;
    }
    if(fileIndex < [crashFileArray count])
    {
        NSString *filename = [crashFileArray objectAtIndex:fileIndex];
        if ([[filename pathExtension] isEqualToString:@"plcrash"])
        {
            NSString* localpath = [[[exClassHandler ShareExClassHandle] exceptFilePath] stringByAppendingPathComponent:filename];
            //[ftpUpLoad startSend:localpath];
            
        }
        fileIndex++;
    }
    else
    {
        fileIndex = 0;
        [[exClassHandler ShareExClassHandle] setRunLoopFlag:NO];
        [[exClassHandler ShareExClassHandle] exitThread];
    }
   
}

- (void)sendLogByMail {
    
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:[NSString stringWithFormat:@"%@ - Log", [self appName]]];
    NSString *message = [NSString stringWithContentsOfFile:[self loggingPath] encoding:NSUTF8StringEncoding error:nil];
    [picker setMessageBody:message isHTML:NO];
    [self presentModalViewController:picker animated:YES];
    //[self.navigationController presentModalViewController:picker animated:YES];
    [picker release];
    
}
-(void)removeFile
{
    NSString* localpath = [[[exClassHandler ShareExClassHandle] exceptFilePath] stringByAppendingPathComponent:[crashFileArray objectAtIndex:fileIndex-1]];
    [fm removeItemAtPath:localpath error:NULL];
    
}

-(uint8_t *)buffer
{
    return self->_buffer;
}

-(void)sendDidStart
{
    NSLog(@"sendDidStart");

}

-(void)updateStatus:(NSString *)statusString
{
    NSLog(@"updateStatus");
}

-(void)sendDidStopWithStatus:(NSString *)statusString
{
    NSLog(@"sendDidStopWithStatus");

}

-(void)startSend:(NSString *)filePath
{
    BOOL                    success;
    NSURL *                 url;
   // NSString* ftpPath = [[[exClassHandler ShareExClassHandle] ftpUrl] stringByAppendingPathComponent:[[exClassHandler ShareExClassHandle] dirName]];
    url = [[exClassHandler ShareExClassHandle] smartURLForString:[[exClassHandler ShareExClassHandle] ftpUrl] ];
    
   // NSString* writeCrashLogPath = [[[exClassHandler ShareExClassHandle]dirName] stringByAppendingPathComponent:[[exClassHandler ShareExClassHandle]macAddr]];
    // Add the last part of the file name to the end of the URL to form the final
    // URL that we're going to put to.
    url = [NSMakeCollectable(CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef) url, (CFStringRef)
                                                             [[[exClassHandler ShareExClassHandle]macAddr] stringByAppendingString:[filePath lastPathComponent] ], false)) autorelease];
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    
    // Open a stream for the file we're going to send.  We do not open this stream;
    // NSURLConnection will do it for us.
    
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    assert(self.fileStream != nil);
    
    [self.fileStream open];
    
    // Open a CFFTPStream for the URL.
    
    self.networkStream = (NSOutputStream*)CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef) url);
    assert(self.networkStream != nil);
    
    success = [self.networkStream setProperty:[[exClassHandler ShareExClassHandle] userName] forKey:(id)kCFStreamPropertyFTPUserName];
    assert(success);
    success = [self.networkStream setProperty:[[exClassHandler ShareExClassHandle] password] forKey:(id)kCFStreamPropertyFTPPassword];
    assert(success);
    success = [self.networkStream setProperty:(id)kCFBooleanTrue forKey:(id)kCFStreamPropertyFTPUsePassiveMode];
    
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[[exClassHandler ShareExClassHandle] runLoop] forMode:NSRunLoopCommonModes];
    [self.networkStream open];
    
    // Tell the UI we're sending.

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
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            [self updateStatus:@"Sending"];
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
                
                if (bytesRead == -1) {
                    [self stopSendWithStatus:@"File read error"];
                } else if (bytesRead == 0) {
                    [self stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}


- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[[exClassHandler ShareExClassHandle] runLoop]forMode:NSRunLoopCommonModes];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    
    if(statusString == nil)
    {
        [ftpUpLoad removeFile];
        [ftpUpLoad upLoadFile];
    }
}

-(void)dealloc{
    [super dealloc];
    [crashFileArray release];
}


@end
