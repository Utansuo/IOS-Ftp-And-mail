//
//  ExceptionHandler.h
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-17.
//
//

#import <Foundation/Foundation.h>
#import "SKPSMTPMessage.h"
#import "exClassHandler.h"
#import "sys/utsname.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

@interface ExceptionHandler : NSObject<SKPSMTPMessageDelegate>
{
    NSException* tempException;

}
@property (nonatomic, strong, readwrite,retain) NSRunLoop *runLoop;
@property (nonatomic, readwrite) BOOL runLoopFlag;

void HandleException(NSException *exception);
void SignalHandler(int signal);
void InstallUncaughtExceptionHandler(void);

+(ExceptionHandler*)exceptionHandlerSingle;

@end
