//
//  exClassHandler.h
//  Unity-iPhone
//
//  Created by yangchao on 13-12-20.
//
//


#define FTPURL   @"192.168.23.227:60012/CrashReport/IOS/"//@"211.151.21.53:17710/CrashReport/IOS/"

#include "SKPSMTPMessage.h"
#include "NSData+Base64Additions.h"
#import "ASIFormDataRequest.h"

@interface exClassHandler : NSObject<ASIHTTPRequestDelegate>{
    NSInteger  fileIndex;
    NSFileManager *fm;
}

@property (nonatomic, strong, readwrite) NSString *   ftpUrl;
@property (nonatomic, strong, readwrite) NSString *   userName;
@property (nonatomic, strong, readwrite) NSString *   password;
@property (nonatomic, strong, readwrite) NSString *   dirName;
@property (nonatomic, strong, readwrite) NSString *   macAddr;
@property (nonatomic, strong, readwrite) NSString *   exceptFilePath;
@property (nonatomic, strong, readwrite,retain) NSRunLoop *runLoop;
@property (nonatomic, readwrite) BOOL runLoopFlag;

@property(nonatomic,assign) UIButton* upLoadBtn;

+(exClassHandler*)ShareExClassHandle;

-(void)setPlace:(float)latitude  logi:(float)longitude;
-(NSURL *)smartURLForString:(NSString *)str;
-(void)getCrashLocalPath:(NSString*)filePath;
-(void)exitThread;
-(void)upLoadFile;
-(NSString*)getFileName;


@end