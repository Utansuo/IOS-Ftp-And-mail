//
//  SendMail.h
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-20.
//
//

#import <Foundation/Foundation.h>
#import "SKPSMTPMessage.h"
#import "exClassHandler.h"

@interface SendMail : NSObject<SKPSMTPMessageDelegate>{

    NSInteger  fileIndex;
    NSFileManager *fm;
    NSArray* crashFileArray;

}

+(SendMail*)sendMaileSingleton;
@end
