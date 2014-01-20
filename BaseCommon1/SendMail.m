//
//  SendMail.m
//  Unity-iPhone
//
//  Created by WU WUYUAN on 14-1-20.
//
//



#import "SendMail.h"

static SendMail* sendMail= nil;
@implementation SendMail

+(SendMail*)sendMaileSingleton{
    if(sendMail == nil)
    {
        sendMail = [[SendMail alloc]init];
      
        [sendMail initFunc];
    }
    return sendMail;
}
-(void)initFunc{
      fileIndex = 0;
    fm = [NSFileManager defaultManager];
    crashFileArray = [[NSArray alloc] initWithArray:[fm contentsOfDirectoryAtPath:[[exClassHandler ShareExClassHandle] exceptFilePath] error:NULL]];
  
    [sendMail send];
}

-(void)send{
     if([crashFileArray count]<=0)
    {
        [[exClassHandler ShareExClassHandle] exitThread];
        return ;
    }
    if(fileIndex < [crashFileArray count])
    {
        NSString *filename = [crashFileArray objectAtIndex:fileIndex];
        if ([[filename pathExtension] isEqualToString:@"log"])
        {
            NSString* localpath = [[[exClassHandler ShareExClassHandle] exceptFilePath] stringByAppendingPathComponent:filename];
            NSData *reader = [NSData dataWithContentsOfFile:localpath];
            NSString* str =[[NSString alloc] initWithData:reader encoding:NSUTF8StringEncoding];
            SKPSMTPMessage* skpSMTMessage = [[SKPSMTPMessage alloc]init];
            skpSMTMessage.fromEmail = @"daxiaojianghutest@163.com";
            skpSMTMessage.toEmail = @"hongfei.wu@chukong-inc.com";
            skpSMTMessage.relayHost = @"smtp.163.com";
            skpSMTMessage.requiresAuth = YES;
            
            skpSMTMessage.login = @"daxiaojianghutest@163.com";
            skpSMTMessage.pass = @"wwy123456";
            skpSMTMessage.ccEmail = @"yangchao@chukong-inc.com,wuyuan.wu@chukong-inc.com";
            skpSMTMessage.wantsSecure = YES;
            skpSMTMessage.delegate = sendMail;

            NSString* subject = [@"DaXiao_IOS_CrashReport_" stringByAppendingString:GetOnlyTime()];
            skpSMTMessage.subject = subject;
            NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/plain",kSKPSMTPPartContentTypeKey,
                                           str,kSKPSMTPPartMessageKey,@"8bit",kSKPSMTPPartContentTransferEncodingKey,nil];
            skpSMTMessage.parts = [NSArray arrayWithObjects:plainPart,nil];
            [skpSMTMessage send];
            [str release];
        }
        fileIndex++;
    }
    else
    {
        fileIndex = 0;
        [[exClassHandler ShareExClassHandle] exitThread];
    }

}

-(void)removeFile
{
    NSString* localpath = [[[exClassHandler ShareExClassHandle] exceptFilePath] stringByAppendingPathComponent:[crashFileArray objectAtIndex:fileIndex-1]];
    [fm removeItemAtPath:localpath error:NULL];
    
}

-(void)messageSent:(SKPSMTPMessage *)message
{
    [message release];
    [sendMail removeFile];
    [sendMail send];
}
-(void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
     [message release];
    if(fileIndex < [crashFileArray count])
    {
        [sendMail send];
    }
    else
    {
        [[exClassHandler ShareExClassHandle] exitThread];

    }
    
}
NSString* GetOnlyTime(){
    NSDate* date = [NSDate date];
    
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:date]  ;
}

@end
