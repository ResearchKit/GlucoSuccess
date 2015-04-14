// 
//  APHWaistTaskViewController.m 
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
 
#import "APHWaistTaskViewController.h"
@import APCAppCore;

static NSString * kWaistStepIntroKey = @"Waist_Step_Intro";
static NSString * kWaistStep101Key = @"Waist_Step_101";
static NSString * kWaistStep102Key = @"Waist_Step_102";

static NSString *kWaistResultDateKey = @"waistResultDateKey";
static NSString *kWaistResultValueKey = @"waistResultValueKey";

@interface APHWaistTaskViewController()

@property (nonatomic, strong) NSNumber *currentWaistValue;

@end

@implementation APHWaistTaskViewController


+ (ORKOrderedTask *)createTask:(APCScheduledTask*) __unused scheduledTask
{
    
    NSMutableArray *steps = [NSMutableArray array];
    {
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kWaistStepIntroKey];
        [steps addObject:step];
    }
    {
        ORKNumericAnswerFormat* format = [[ORKNumericAnswerFormat alloc] initWithStyle:ORKNumericAnswerStyleDecimal
                                                                                    unit:@"inches"];
        format.minimum = @(20);
        format.maximum = @(60);
        ORKQuestionStep* step = [ORKQuestionStep questionStepWithIdentifier:kWaistStep101Key
                                                                        title:@"What is your waist measurement?"
                                                                       answer:format];
        
        step.optional = NO;
        [steps addObject:step];
    }
    {
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kWaistStep102Key];
        [steps addObject:step];
    }
    
    ORKOrderedTask  *task = [[ORKOrderedTask alloc] initWithIdentifier:@"WaistMeasurement" steps:steps];
    
    return  task;
}

- (NSString *)createResultSummary
{
    NSError *error = nil;
    
    NSDictionary *waistResult = @{kWaistResultValueKey: self.currentWaistValue};
    
    NSData *waistEntry = [NSJSONSerialization dataWithJSONObject:waistResult options:0 error:&error];
    NSString *contentString = [[NSString alloc] initWithData:waistEntry encoding:NSUTF8StringEncoding];
    
    return contentString;
}

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *)taskViewController viewControllerForStep:(ORKStep *)step
{
    APCStepViewController  *controller = nil;
    if ([step.identifier isEqualToString:kWaistStepIntroKey]) {
        controller = (APCInstructionStepViewController*) [[UIStoryboard storyboardWithName:@"APCInstructionStep" bundle:[NSBundle appleCoreBundle]] instantiateInitialViewController];
        APCInstructionStepViewController * instController = (APCInstructionStepViewController*) controller;
        instController.imagesArray = @[@"waistmeasurement-Icon1", @"waistmeasurement-Icon2", @"waistmeasurement-Icon3"];
        instController.headingsArray = @[@"Find Your Waist", @"Measuring", @"Reading the Measurement"];
        instController.messagesArray = @[@"Locate the midpoint between top of your hips and the base of your ribs just above the navel. You may need to raise or remove your clothing for accuracy.",
                                         @"Using soft tape measure, start at your navel and wrap around your waist. The tape should fit snugly without digging into your skin.",
                                         @"Look at the place on the tape where the zero end meets the other end of the tape measure. The location of this meeting point is your waist measurement."];
        controller.delegate = self;
        controller.step = step;
    } else if ([step.identifier isEqualToString:kWaistStep102Key]) {
        for (ORKStepResult *surveyQuestion in taskViewController.result.results) {
            if ([surveyQuestion.identifier isEqualToString:kWaistStep101Key]) {
                ORKNumericQuestionResult *questionResult = [surveyQuestion.results firstObject];
                
                // Once we have set this property, the summary view will be shown.
                // Upon dismissing that view, the createSummary method will be called by the
                // base class and the results written to Core Data.
                self.currentWaistValue = questionResult.numericAnswer;
            }
        }
        
        APCSimpleTaskSummaryViewController* c = [[APCSimpleTaskSummaryViewController alloc] initWithNibName:nil bundle:[NSBundle appleCoreBundle]];
        (void)c.view;
        c.delegate = self;
        c.step = step;
        c.youCanCompareMessage.text = @"";
        controller = c;
    }
    
    return controller;
}

@end
