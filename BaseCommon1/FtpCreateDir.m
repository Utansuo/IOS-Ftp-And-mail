//
//  CreateDir.m
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-2.
//
//

#import "FtpCreateDir.h"

#import "exClassHandler.h"
#import "FtpUploadFile.h"
static FtpCreateDir* ftpCreateDir = nil;

@implementation FtpCreateDir

+(FtpCreateDir*)FtpCreateDirSingleton
{
   if(ftpCreateDir == nil)
   {
       ftpCreateDir = [[FtpCreateDir alloc]init];
       [ftpCreateDir startCreate];
   }
    return ftpCreateDir;
}


-(void)createDidStopWithStatus:(NSString *)statusString
{
    if(statusString == nil)
    {
       [FtpUploadFile FtpUpLoadSingleton];
    }
   
}

-(void)startCreate
{
    BOOL                    success;
    NSURL *                 url;

    assert(self.networkStream == nil);      // don't tap create twice in a row!

    // First get and check the URL.

    url = [[exClassHandler ShareExClassHandle] smartURLForString:[[exClassHandler ShareExClassHandle] ftpUrl] ];
    success = (url != nil);

    if (success) {
        // Add the directory name to the end of the URL to form the final URL
        // that we're going to create.  CFURLCreateCopyAppendingPathComponent will
        // percent encode (as UTF-8) any wacking characters, which is the right thing
        // to do in the absence of application-specific knowledge about the encoding
        // expected by the server.
        url =[NSMakeCollectable(CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef) url, (CFStringRef)
                                                                 [[[exClassHandler ShareExClassHandle] dirName ]lastPathComponent], true)) autorelease];
        success = (url != nil);
    }

    // If the URL is bogus, let the user know.  Otherwise kick off the connection.

    // Open a CFFTPStream for the URL.

    self.networkStream = (NSOutputStream*)CFWriteStreamCreateWithFTPURL(NULL, ( CFURLRef) url);

    assert(self.networkStream != nil);

    success = [self.networkStream setProperty:[[exClassHandler ShareExClassHandle] userName] forKey:(id)kCFStreamPropertyFTPUserName];
    assert(success);
    success = [self.networkStream setProperty:[[exClassHandler ShareExClassHandle] password] forKey:(id)kCFStreamPropertyFTPPassword];
    assert(success);

    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[[exClassHandler ShareExClassHandle] runLoop] forMode:NSRunLoopCommonModes];
    [self.networkStream open];
}

-(void)stopCreateWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[[exClassHandler ShareExClassHandle] runLoop]forMode:NSRunLoopCommonModes];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    [self createDidStopWithStatus:statusString];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
#pragma unused(aStream)
    assert(aStream == self.networkStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
           
            // Despite what it says in the documentation <rdar://problem/7163693>,
            // you should wait for the NSStreamEventEndEncountered event to see
            // if the directory was created successfully.  If you shut the stream
            // down now, you miss any errors coming back from the server in response
            // to the MKD command.
            //
            // [self stopCreateWithStatus:nil];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError   err;
            
            // -streamError does not return a useful error domain value, so we
            // get the old school CFStreamError and check it.
            
            err = CFWriteStreamGetError( (CFWriteStreamRef) self.networkStream );
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self stopCreateWithStatus:[NSString stringWithFormat:@"FTP error %d", (int) err.error]];
            } else {
                [self stopCreateWithStatus:@"Stream open error"];
            }
        } break;
        case NSStreamEventEndEncountered: {
            [self stopCreateWithStatus:nil];
        } break;
        default: {
            assert(NO);
        } break;
    }
}

@end
