// 
//  APHGlucoseLogTaskViewController.m 
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
 
#import "APHGlucoseLogTaskViewController.h"
#import "APHGlucoseLogViewController.h"
#import "APHGlucoseEntryViewController.h"

static NSString *kMainStudyIdentifier = @"com.diabetes.GlucoseLog";
static NSString *kGlucoseLogListStep = @"glucoseLogListStep";
static NSString *kGlucoseLogEntryStep = @"glucoseLogEntryStep";
static NSString *kGlucoseLogCompleteStep = @"glucoseLogCompleteStep";

static NSString *kGlucoseContentDictionaryKey = @"glucoseContentDictionaryKey";

@interface APHGlucoseLogTaskViewController () <UINavigationControllerDelegate>

@property (nonatomic, strong) APCGroupedScheduledTask *groupedTask;

@end

@implementation APHGlucoseLogTaskViewController


#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.showsProgressInNavigationBar = NO;
    self.navigationBar.topItem.title = NSLocalizedString(@"Glucose Levels", @"Glucose Levels");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Task

+ (ORKOrderedTask *)createTask:(APCScheduledTask *) __unused scheduledTask
{
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    {
        // Glucose Log List Step
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kGlucoseLogListStep];
        step.title = NSLocalizedString(@"Glucose Levels", @"Glucose Levels");
        
        [steps addObject:step];
    }
    {
        // Glucose Log Entry Step
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kGlucoseLogEntryStep];
        step.title = NSLocalizedString(@"Glucose Entry", @"Glucose Entry");
        
        [steps addObject:step];
    }
    
    {
        // Complete Step
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kGlucoseLogCompleteStep];
        step.title = NSLocalizedString(@"Glucose Entry Complete", @"Glucose Entry Complete");
        
        [steps addObject:step];
    }
    
    ORKOrderedTask  *task = [[ORKOrderedTask alloc] initWithIdentifier:@"Glucose Levels" steps:steps];
    
    return task;
}

#pragma mark - Task View Delegates

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *) __unused taskViewController viewControllerForStep:(ORKStep *)step
{
    ORKStepViewController *stepVC = nil;
    UIStoryboard *sbGlucoseLog = [UIStoryboard storyboardWithName:@"APHGlucoseLog" bundle:nil];
    
    if (step.identifier == kGlucoseLogListStep) {
        APHGlucoseLogViewController *glucoseVC = [sbGlucoseLog instantiateInitialViewController];
        
        glucoseVC.delegate = self;
        glucoseVC.step = step;
        
        stepVC = glucoseVC;
    } else if (step.identifier == kGlucoseLogEntryStep) {
        APHGlucoseEntryViewController *glucoseEntryVC = [sbGlucoseLog instantiateViewControllerWithIdentifier:@"GlucoseLogEntry"];
        
        glucoseEntryVC.delegate = self;
        glucoseEntryVC.step = step;
        glucoseEntryVC.tasks = self.groupedTask;
        
        stepVC = glucoseEntryVC;
    } else {
        // Task Complete
        Class glucoseComplete = [APCSimpleTaskSummaryViewController class];
        APCStepViewController *completeVC = [[glucoseComplete alloc] initWithNibName:nil bundle:[NSBundle appleCoreBundle]];
        
        completeVC.delegate = self;
        completeVC.step = step;
        
        stepVC = completeVC;
    }
    
    return stepVC;
}

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(nullable NSError *) __unused error
{
    switch (reason) {
        case ORKTaskViewControllerFinishReasonDiscarded:
        case ORKTaskViewControllerFinishReasonSaved:
        case ORKTaskViewControllerFinishReasonFailed:
        default: //ORKTaskViewControllerResultCompleted
            [self taskViewControllerDidComplete:self];
            break;
    }
}

- (void)taskViewControllerDidComplete:(ORKTaskViewController *) __unused taskViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Step Delegates

//- (void)stepViewControllerDidFinish:(ORKStepViewController *)stepViewController
//                navigationDirection:(ORKStepViewControllerNavigationDirection)direction
- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction
{
    if ([stepViewController.step.identifier isEqualToString:kGlucoseLogListStep]) {
        APHGlucoseLogViewController *logVC = (APHGlucoseLogViewController *)stepViewController;
        
        self.groupedTask = logVC.selectedTask;
    }
    
    [super stepViewController:stepViewController didFinishWithNavigationDirection:direction];
}

@end
