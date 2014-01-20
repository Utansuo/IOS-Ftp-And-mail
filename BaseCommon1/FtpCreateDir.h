//
//  CreateDir.h
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-2.
//
//

#import <Foundation/Foundation.h>
#include <CFNetwork/CFNetwork.h>
@interface FtpCreateDir : NSObject<NSStreamDelegate>
@property (nonatomic, strong, readwrite) NSOutputStream *  networkStream;

-(void)startCreate;
+(FtpCreateDir*)FtpCreateDirSingleton;
@end
