//
//  FtpCheckDir.h
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-2.
//
//

#import <Foundation/Foundation.h>

@interface FtpCheckDir : NSObject<NSStreamDelegate>
@property (nonatomic, strong, readwrite) NSInputStream *   networkStream;
@property (nonatomic, strong, readwrite) NSMutableData *   listData;
@property (nonatomic, strong, readwrite) NSArray *   nsArray;
@property (nonatomic, strong, readwrite) NSString *   fileList;

+(FtpCheckDir*)FtpCheckDirSingleton;

- (void)startReceive;
@end
