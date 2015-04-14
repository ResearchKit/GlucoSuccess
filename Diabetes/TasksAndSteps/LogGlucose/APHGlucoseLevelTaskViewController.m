// 
//  APHGlucoseLevelTaskViewController.m 
//  GlucoSuccess 
// 
// Copyright (c) 2015, Massachusetts General Hospital. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
#import "APHGlucoseLevelTaskViewController.h"
#import "APHGlucoseLevelsMealTimesViewController.h"

static NSString *kGlucoseLogEntryStep = @"glucoseLogEntryStep";
static NSString *kGlucoseLevelHasValueKey = @"hasValue";

@interface APHGlucoseLevelTaskViewController ()

@property (nonatomic, strong) ORKStepResult *stepResult;

@end

@implementation APHGlucoseLevelTaskViewController

+ (ORKOrderedTask *)createTask:(APCScheduledTask *) __unused scheduledTask
{
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    {
        // Glucose Log Entry Step
        ORKQuestionStep *step = [[ORKQuestionStep alloc] initWithIdentifier:kGlucoseLogEntryStep];
        step.title = NSLocalizedString(@"Glucose Entry", @"Glucose Entry");
        
        [steps addObject:step];
    }
    
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:@"Glucose Levels" steps:steps];
    
    return task;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSString *)createResultSummary
{
    NSError *error = nil;
    
    NSData *glucoseEntry = [NSJSONSerialization dataWithJSONObject:self.glucoseLevel options:0 error:&error];
    NSString *contentString = [[NSString alloc] initWithData:glucoseEntry encoding:NSUTF8StringEncoding];
    
    return contentString;
}

- (ORKTaskResult *)result
{
    ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:kGlucoseLogEntryStep
                                                                  taskRunUUID:self.taskRunUUID
                                                              outputDirectory:nil];
    taskResult.results = @[self.glucoseLevel];
    
    return taskResult;
}

- (void)stepViewControllerDidFinish:(ORKStepViewController *)stepViewController
                navigationDirection:(ORKStepViewControllerNavigationDirection)direction
{
    [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
}

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(nullable NSError *) __unused error
{
    switch (reason) {
        case ORKTaskViewControllerFinishReasonDiscarded:
        case ORKTaskViewControllerFinishReasonSaved:
        case ORKTaskViewControllerFinishReasonFailed:
            break;
            
        default: //ORKTaskViewControllerResultCompleted
            [self taskViewControllerDidComplete:self];
            break;
    }
}

- (void)taskViewControllerDidComplete:(ORKTaskViewController *)taskViewController
{
    NSError *contentError = nil;
    NSString *stepIdentifier = @"glucoseLogData";
    APCDataResult *contentModel = [[APCDataResult alloc] initWithIdentifier:stepIdentifier];
    
    // We need to check if the user selected 'Not Measured' for their glucose reading.
    // If so, we will remove the value key and set the 'hasValue' key to NO; otherwise
    // the hasValue key will be set to YES.
    
    NSMutableDictionary *glucoseReadingEntry = [self.glucoseLevel mutableCopy];
    NSNumber *glucoseReadingValue = self.glucoseLevel[kGlucoseLevelValueKey];
    
    if ([glucoseReadingValue isEqual:[NSNull null]]) {
        [glucoseReadingEntry removeObjectForKey:kGlucoseLevelValueKey];
        glucoseReadingEntry[kGlucoseLevelHasValueKey] = @(NO);
    } else {
        glucoseReadingEntry[kGlucoseLevelHasValueKey] = @(YES);
    }
    
    contentModel.data = [NSJSONSerialization dataWithJSONObject:glucoseReadingEntry options:0 error:&contentError];
    
    if (!contentModel.data) {
        if (contentError) {
            APCLogError2(contentError);
        }
    } else {
        self.stepResult = [[ORKStepResult alloc] initWithStepIdentifier:kGlucoseLogEntryStep results:@[contentModel]];
    }
    
    [self processTaskResult];
    
    [self.scheduledTask completeScheduledTask];
    
    APCAppDelegate * appDelegate = (APCAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.scheduler updateScheduledTasksIfNotUpdating:NO];
    
    [taskViewController dismissViewControllerAnimated:YES completion:nil];
    
    APCLogEventWithData(kTaskEvent, (@{
                                       @"task_status":@"Completed",
                                       @"task_title": self.scheduledTask.task.taskTitle,
                                       @"task_view_controller":NSStringFromClass([self class])
                                       }));
}

- (NSString *)taskResultsFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = [[paths lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", self.taskRunUUID.UUIDString]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError * fileError;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&fileError];
        
        APCLogError2(fileError);
    }
    
    return path;
}

- (void) processTaskResult
{
    NSString *resultSummary = [self createResultSummary];
    APCDataArchiver *archiver = [[APCDataArchiver alloc] initWithResults:@[self.stepResult]
                                                           itemIdentifier:self.stepResult.identifier
                                                                  runUUID:self.taskRunUUID];
    
    /*
     See comment at bottom of this method.
     */
    #ifdef USE_DATA_VERIFICATION_CLIENT
    
        archiver.preserveUnencryptedFile = YES;
    
    #endif
    
    
    NSString *archiveFileName = [archiver writeToOutputDirectory:self.taskResultsFilePath];
    
    [self storeInCoreDataWithFileName:archiveFileName
                        resultSummary:resultSummary
                         usingContext:self.localContext];
    
    
    /*
     This will COPY the unencrypted file to a local
     server.  (The code above here uploads it to Sage.)
     We're #if-ing it to make sure this code isn't
     accessible to Bad Guys in production.  Even if
     the code called, if it's in RAM at all, it can
     be exploited.
     */
    #ifdef USE_DATA_VERIFICATION_CLIENT
    
        [APCDataVerificationClient uploadDataFromFileAtPath: archiver.unencryptedFilePath];
    
    #endif
    
}

@end
