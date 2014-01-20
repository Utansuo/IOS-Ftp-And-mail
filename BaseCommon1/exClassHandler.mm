//  Unity-iPhone
//
//  Created by yangchao on 13-10-16.
//
//

#import "exClassHandler.h"
#import <CoreLocation/CLGeocoder.h>
#import <CoreLocation/CLPlacemark.h>
#import "iPhone_Sensors.h"
#import "iPhone_View.h"
#import <Foundation/NSThread.h>
#import "ExceptionHandler.h"
#import "SendMail.h"

#include <stdio.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <stdlib.h>



static exClassHandler* exhandle = nil;

@implementation exClassHandler

@synthesize ftpUrl = _ftpUrl;
@synthesize userName = _userName;
@synthesize password = _password;
@synthesize dirName = _dirName;
@synthesize exceptFilePath = _exceptFilePath;
@synthesize runLoop = _runLoop;
@synthesize runLoopFlag = _runLoopFlag;
@synthesize macAddr = _macAddr;

@synthesize upLoadBtn = _upLoadBtn;

+(exClassHandler*)ShareExClassHandle{
    
    if ( exhandle == nil )
    {
        exhandle = [[exClassHandler alloc] init];
        [exhandle initInfo ];
    }
    return exhandle;
}

-(void)setPlace:(float)latitude  logi:(float)longitude
{
    CLGeocoder* geocoder=[[CLGeocoder alloc]init];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error == nil &&[placemarks count] > 0)
         {
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             
             NSString *str = [NSString stringWithFormat:@"%@-%@-%@", placemark.country, [placemark.addressDictionary objectForKey:@"State"],placemark.subLocality];
             
             UnitySendMessage("RootMain", "di_Place", [str UTF8String]);
         }
         else if (error == nil &&[placemarks count] == 0)
         {
             NSLog(@"No results were returned.");
         }
         else if (error != nil)
         {
             NSLog(@"An error occurred = %@", error);
         }
     }];
}

-(void)initInfo
{
     exhandle.exceptFilePath = applicationDocumentsDirectory();
    NSThread* myThread  = [[NSThread alloc] initWithTarget:exhandle selector:@selector(threadInMainMethod:) object:nil];
    [myThread start];
    self.runLoopFlag  = TRUE;
   
    [ExceptionHandler exceptionHandlerSingle];
}

NSString *applicationDocumentsDirectory() {
    
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"CrashReport"];
    
}

-(void)threadInMainMethod:(id)sender{
  
    
    self.runLoop = [NSRunLoop currentRunLoop];
    [SendMail sendMaileSingleton];
    while (self.runLoopFlag ) {

        [self.runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

-(void)exitThread{
      self.runLoopFlag  = FALSE;
    [ NSThread exit];
}



-(NSString*) getFileName{
    
    unsigned long long seconds = (unsigned long long)[[NSDate date] timeIntervalSince1970];
	NSString* fileName = [ getMACAddr() stringByAppendingString:[NSString stringWithFormat:@"%llu", seconds]];
    return fileName;
}

NSString* getMACAddr()
{
    
	int                    mib[6];
	size_t                len;
	char                *buf;
	unsigned char        *ptr;
	struct if_msghdr    *ifm;
	struct sockaddr_dl    *sdl;
	
	mib[0] = CTL_NET;
	mib[1] = AF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_LINK;
	mib[4] = NET_RT_IFLIST;
	
	if ((mib[5] = if_nametoindex("en0")) == 0) {
		//printf("Error: if_nametoindex error/n");
		return@"";
	}
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
		//printf("Error: sysctl, take 1/n");
		return@"";
	}
	
	if ((buf = (char *)malloc(len)) == NULL) {
		//printf("Could not allocate memory. error!/n");
		return @"";
	}
	
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		//printf("Error: sysctl, take 2");
		return @"";
	}
	
	ifm = (struct if_msghdr *)buf;
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x-", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	free(buf);
    return outstring;
}

-(void)getCrashLocalPath:(NSString *)filePath{
    
    self.exceptFilePath = filePath;
    
}

- (NSURL *)smartURLForString:(NSString *)str{
    NSURL *     result;
    NSString *  trimmedStr;
    NSRange     schemeMarkerRange;
    NSString *  scheme;
    
    assert(str != nil);
    
    result = nil;
    
    trimmedStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ( (trimmedStr != nil) && ([trimmedStr length] != 0) ) {
        schemeMarkerRange = [trimmedStr rangeOfString:@"://"];
        
        if (schemeMarkerRange.location == NSNotFound) {
            result = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://%@", trimmedStr]];
        } else {
            scheme = [trimmedStr substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
            assert(scheme != nil);
            
            if ( ([scheme compare:@"ftp"  options:NSCaseInsensitiveSearch] == NSOrderedSame) ) {
                result = [NSURL URLWithString:trimmedStr];
            } else {
                // It looks like this is some unsupported URL scheme.
            }
        }
    }
    return result;
}

-(void)upLoadFile
{
    _upLoadBtn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    _upLoadBtn.frame = CGRectMake(0, 0, 100, 30);
    [_upLoadBtn setTitle:@"upLoad" forState:UIControlStateNormal];
    [_upLoadBtn addTarget:self action:@selector(statrUpLoad:) forControlEvents:UIControlEventTouchUpInside];
    [UnityGetGLView() addSubview:_upLoadBtn];    
}

-(void)statrUpLoad:(id)sender
{
    NSURL* url = [NSURL URLWithString:@"http://192.168.24.188/test/crashlogger.php"];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:@"hello 小雨" forKey:@"hi man"];
    [request setDelegate: exhandle];
    [request startAsynchronous];
    
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    NSString *responseString = [request responseString];
      NSLog(@"%@",responseString);
    // Use when fetching binary data
    //NSData *responseData = [request responseData];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"%@",error);
}



@end