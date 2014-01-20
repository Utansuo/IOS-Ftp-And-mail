//
//  ExceptionHandler.m
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-17.
//
//

#import "ExceptionHandler.h"



NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

static ExceptionHandler * exceptionHandler = nil;

@implementation ExceptionHandler
@synthesize runLoop = _runLoop;
@synthesize runLoopFlag = _runLoopFlag;

+(ExceptionHandler*)exceptionHandlerSingle
{
    if(exceptionHandler == nil)
    {
      exceptionHandler = [[ExceptionHandler alloc]init];
        [exceptionHandler initFunc];
    }
    return exceptionHandler;
}

-(void)initFunc{
    
    InstallUncaughtExceptionHandler();
     }


+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
         i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         i++)
    {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

NSString *applicationDocumentsDirectory() {
    
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Crash"];
    
}

- (void)handleException:(NSException *)exception
{
    UIDevice* uiDevice = [UIDevice currentDevice];
    
    NSBundle* nsBundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [nsBundle infoDictionary];
    NSString* crashInfo = [NSString stringWithFormat:@"Identifier:%@\nVersion:%@\nOS Version:%@ %@\nHardware Model:%@\n channel:%@\n Reason:%@\n  userInfo:%@",
                           [nsBundle bundleIdentifier],
                           [infoDictionary objectForKey:@"CFBundleVersion"],
                           [uiDevice systemName],
                           [uiDevice systemVersion],
                           [self deviceString],
                           @"渠道好",
                           [exception reason],
                           [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedLong: 0755] forKey: NSFilePosixPermissions];
    NSString* path = [[exClassHandler ShareExClassHandle]  exceptFilePath];
    if (![fileManager fileExistsAtPath:path]) {
         [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:attributes error:NULL];
    }
    path = [path stringByAppendingPathComponent:[[exClassHandler ShareExClassHandle]getFileName] ];
    path = [path stringByAppendingString:@".log"];
    [crashInfo writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
//
//	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
//	CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
//	while (true)
//	{
//        
//		for (NSString *mode in (NSArray *)allModes)
//		{
//			CFRunLoopRunInMode((CFStringRef)mode, 0.01, false);
//		}
//	}
//	
//	CFRelease(allModes);
    
//	NSSetUncaughtExceptionHandler(NULL);
//	signal(SIGABRT, SIG_DFL);
//	signal(SIGILL, SIG_DFL);
//	signal(SIGSEGV, SIG_DFL);
//	signal(SIGFPE, SIG_DFL);
//	signal(SIGBUS, SIG_DFL);
//	signal(SIGPIPE, SIG_DFL);
//	
//	if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
//	{
//		kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
//	}
//	else
//	{
//		[exception raise];
//	}
    
}

-(NSString*)deviceString
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}

-(void) dealloc
{
    [super dealloc];
}
@end

void HandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSArray *callStack = [ExceptionHandler backtrace];
	NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[[ExceptionHandler alloc] init] autorelease]
     performSelectorOnMainThread:@selector(handleException:)
     withObject:
     [NSException
      exceptionWithName:[exception name]
      reason:[exception reason]
      userInfo:userInfo]
     waitUntilDone:YES];
}

void SignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSMutableDictionary *userInfo =
    [NSMutableDictionary
     dictionaryWithObject:[NSNumber numberWithInt:signal]
     forKey:UncaughtExceptionHandlerSignalKey];
    
	NSArray *callStack = [ExceptionHandler backtrace];
	[userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[[ExceptionHandler alloc] init] autorelease]
     performSelectorOnMainThread:@selector(handleException:)
     withObject:
     [NSException
      exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
      reason:
      [NSString stringWithFormat:
       NSLocalizedString(@"Signal %d was raised.", nil),
       signal]
      userInfo:
      [NSDictionary
       dictionaryWithObject:[NSNumber numberWithInt:signal]
       forKey:UncaughtExceptionHandlerSignalKey]]
     waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler(void)
{
	NSSetUncaughtExceptionHandler(&HandleException);
	signal(SIGABRT, SignalHandler);
	signal(SIGILL, SignalHandler);
	signal(SIGSEGV, SignalHandler);
	signal(SIGFPE, SignalHandler);
	signal(SIGBUS, SignalHandler);
	signal(SIGPIPE, SignalHandler);
}

