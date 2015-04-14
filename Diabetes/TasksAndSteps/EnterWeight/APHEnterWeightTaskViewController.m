// 
//  APHEnterWeightTaskViewController.m 
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
 
#import "APHEnterWeightTaskViewController.h"
#import <APCAppCore/APCAppCore.h>

static NSString * kEnterWeightStepIntroKey = @"EnterWeight_Step_Intro";
static NSString * kEnterWeightStep101Key = @"EnterWeight_Step_101";
static NSString * kEnterWeightStep102Key = @"EnterWeight_Step_102";

@implementation APHEnterWeightTaskViewController

+ (ORKOrderedTask *)createTask:(APCScheduledTask*) __unused scheduledTask
{
    
    NSMutableArray *steps = [NSMutableArray array];
    {
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kEnterWeightStepIntroKey];
        [steps addObject:step];
    }
    {
        ORKHealthKitQuantityTypeAnswerFormat * format = [ORKHealthKitQuantityTypeAnswerFormat answerFormatWithQuantityType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                                                                                        unit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitPound]
                                                                                                                       style:ORKNumericAnswerStyleDecimal];
        ORKQuestionStep* step = [ORKQuestionStep questionStepWithIdentifier:kEnterWeightStep101Key
                                                                     title:@"How much do you weigh?"
                                                                       answer:format];
        step.optional = NO;
        [steps addObject:step];
    }
    {
        ORKStep* step = [[ORKStep alloc] initWithIdentifier:kEnterWeightStep102Key];
        [steps addObject:step];
    }
    
    ORKOrderedTask  *task = [[ORKOrderedTask alloc] initWithIdentifier:@"WeightMeasurement" steps:steps];
    
    return  task;
}

- (BOOL)taskViewController:(ORKTaskViewController *)taskViewController shouldPresentStep:(ORKStep *)step
{
    BOOL shouldShowStep = YES;
    
    if ([step.identifier isEqualToString:kEnterWeightStep102Key]) {
        NSArray *stepResults = self.result.results;
        
        for (ORKStepResult *result in stepResults) {
            for (ORKNumericQuestionResult *stepResult in result.results) {
                NSNumber *stepAnswer = stepResult.numericAnswer;
                
                if ([stepAnswer integerValue] < 25 || stepResult.numericAnswer == (NSNumber *)[NSNull null]) {
                    shouldShowStep = NO;
                    break;
                }
            }
            
            if (!shouldShowStep) {
                UIAlertController* alerVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid Weight",
                                                                                                          @"Invalid Weight")
                                                                                message:NSLocalizedString(@"Please enter a valid value for your weight.",
                                                                                                          @"Please enter a valid value for your weight.")
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                
                UIAlertAction* ok = [UIAlertAction
                                     actionWithTitle:@"OK"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * __unused action) {
                                         [alerVC dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
                
                
                [alerVC addAction:ok];
                
                [taskViewController presentViewController:alerVC animated:NO completion:nil];
                break;
            }
        }
    }
    
    return shouldShowStep;
}

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *)taskViewController viewControllerForStep:(ORKStep *)step
{
    APCStepViewController  *controller = nil;
    if ([step.identifier isEqualToString:kEnterWeightStepIntroKey]) {
        controller = (APCInstructionStepViewController*) [[UIStoryboard storyboardWithName:@"APCInstructionStep" bundle:[NSBundle appleCoreBundle]] instantiateInitialViewController];
        APCInstructionStepViewController * instController = (APCInstructionStepViewController*) controller;
        instController.imagesArray = @[@"weightmeasurement-Icon1", @"weightmeasurement-Icon2", @"weightmeasurement-Icon3"];
        instController.headingsArray = @[@"Consistent Time of Day", @"Consistent Clothing", @"Use the Same Scale"];
        instController.messagesArray = @[@"It is best to weigh yourself at a regular hour, every time. A good time can be early in the morning before eating.",
                                         @"For an increased level of accuracy, wear a similar outfit when weighing yourself each time.",
                                         @"Using the same scale every time you weigh yourself will produce the most accurate readings."];
        controller.delegate = self;
        controller.step = step;
    } else if ([step.identifier isEqualToString:kEnterWeightStep102Key]) {
        for (ORKStepResult *surveyQuestion in taskViewController.result.results) {
            if ([surveyQuestion.identifier isEqualToString:kEnterWeightStep101Key]) {
                ORKNumericQuestionResult *questionResult = [surveyQuestion.results firstObject];
                
                NSNumber *weightValue = questionResult.numericAnswer;
                
                // Write results to HealthKit
                APCAppDelegate *apcDelegate = (APCAppDelegate*)[[UIApplication sharedApplication] delegate];
                //
                HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:[HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitPound]
                                                              doubleValue:[weightValue doubleValue]];
                
                apcDelegate.dataSubstrate.currentUser.weight = weightQuantity;
            }
        }
        
        
        controller = [[APCSimpleTaskSummaryViewController alloc] initWithNibName:nil bundle:[NSBundle appleCoreBundle]];
        controller.delegate = self;
        controller.step = step;
    }
    
    return controller;
}

@end
