//
//  APHSevenDayFitnessAllocationViewController.m
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

#import "APHSevenDayFitnessAllocationTaskViewController.h"

static NSString *kMainStudyIdentifier = @"com.glucoSuccess.sevenDayFitnessAllocation";
static NSString *kSevenDayFitnessInstructionStep = @"sevenDayFitnessInstructionStep";
static NSString *kSevenDayFitnessActivityStep = @"sevenDayFitnessActivityStep";
static NSString *kSevenDayFitnessCompleteStep = @"sevenDayFitnessCompleteStep";

@interface APHSevenDayFitnessAllocationTaskViewController ()

@end

@implementation APHSevenDayFitnessAllocationTaskViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.showsProgressInNavigationBar = NO;

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationBar.topItem.title = NSLocalizedString(@"Activity Tracker", nil);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Task

+ (ORKOrderedTask *)createTask:(APCScheduledTask *) __unused scheduledTask
{
    NSMutableArray *steps = [[NSMutableArray alloc] init];
    
    {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:kSevenDayFitnessInstructionStep];
        step.title = NSLocalizedString(@"Activity Tracker", @"Activity Tracker");
        step.detailText = @"Some instructions";
        
        [steps addObject:step];
    }
    
    {
        // Seven Day Fitness Allocation Step
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kSevenDayFitnessActivityStep];
        step.title = NSLocalizedString(@"Activity Tracker", @"Activity Tracker");
        step.text = NSLocalizedString(@"Get Ready!", @"Get Ready");
        
        [steps addObject:step];
    }
    
    ORKOrderedTask  *task = [[ORKOrderedTask alloc] initWithIdentifier:@"sevenDayFitnessAllocation" steps:steps];
    
    return task;
}

#pragma mark - Task View Delegates

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *) __unused taskViewController viewControllerForStep:(ORKStep *)step
{
    ORKStepViewController *stepVC = nil;
    
    if (step.identifier == kSevenDayFitnessInstructionStep) {
        APCInstructionStepViewController *controller = [[UIStoryboard storyboardWithName:@"APCInstructionStep"
                                                                                  bundle:[NSBundle appleCoreBundle]] instantiateInitialViewController];
        
        controller.imagesArray = @[@"tutorial-2", @"tutorial-1"];
        controller.headingsArray = @[
                                     NSLocalizedString(@"Keep Your Phone On You", @""),
                                     NSLocalizedString(@"Activity Tracker", @"")
                                    ];
        controller.messagesArray = @[
                                     NSLocalizedString(@"To ensure the accuracy of this task, keep your phone on you at all times.", @""),
                                     NSLocalizedString(@"During the next week, your fitness allocation will be monitored, analyzed, and available to you in real time.", @"")
                                    ];
        
        controller.delegate = self;
        controller.step = step;
        
        stepVC = controller;
    } else if (step.identifier == kSevenDayFitnessActivityStep) {
        UIStoryboard *sbActivityTracking = [UIStoryboard storyboardWithName:@"APCActivityTracking" bundle:[NSBundle appleCoreBundle]];
        APCActivityTrackingStepViewController *activityVC = [sbActivityTracking instantiateInitialViewController];
        
        activityVC.delegate = self;
        activityVC.step = step;
        
        stepVC = activityVC;
    }
    
    return stepVC;
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error
{
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    
    [super taskViewController:taskViewController didFinishWithReason:reason error:error];
}


@end
