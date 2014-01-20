//
//  FtpUploadFile.h
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-2.
//
//

#import <Foundation/Foundation.h>
#include <MessageUI/MessageUI.h>
#include <CFNetwork/CFNetwork.h>
enum {
    kSendBufferSize = 32768
};
@interface FtpUploadFile : NSObject<NSStreamDelegate,MFMailComposeViewControllerDelegate>
{
    uint8_t _buffer[kSendBufferSize];
    NSInteger  fileIndex;
    NSFileManager *fm;
    NSArray* crashFileArray;
   
}

@property (nonatomic, strong, readwrite) NSOutputStream *  networkStream;
@property (nonatomic, strong, readwrite) NSInputStream *   fileStream;
@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;

+(FtpUploadFile*)FtpUpLoadSingleton;

-(void)startSend:(NSString*)filePath;
-(void)removeFile;
-(void)upLoadFile;
@end
