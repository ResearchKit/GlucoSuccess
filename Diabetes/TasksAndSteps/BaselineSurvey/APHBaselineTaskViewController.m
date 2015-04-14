// 
//  APHBaselineTaskViewController.m 
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
 
#import "APHBaselineTaskViewController.h"
#import "APHBaselineSurvey.h"

@import APCAppCore;

@interface APHBaselineTaskViewController()

@property (nonatomic) BOOL shouldShowResultsStep;

@end

@implementation APHBaselineTaskViewController

+ (ORKOrderedTask *)createTask:(APCScheduledTask*) __unused scheduledTask
{
    APHBaselineSurvey *task = [[APHBaselineSurvey alloc] init];

    return task;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.shouldShowResultsStep = YES;
    
    self.showsProgressInNavigationBar = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (BOOL)taskViewController:(ORKTaskViewController *) __unused taskViewController shouldPresentStep:(ORKStep *)step
{
    BOOL shouldShowStep = YES;
    
    if ([step.identifier isEqualToString:kBaselineStepHealthDevice]) {
        
        NSString *messageTitle = nil;
        NSString *messageBody = nil;
        
        shouldShowStep = [self questionStepResultFieldsAreComplete:kBaselineStepMedicationList
                                                             title:&messageTitle
                                                           message:&messageBody];
        
        if (!shouldShowStep) {
            
            [self showAlert:messageTitle
                 andMessage:messageBody];
            
        } else if (!self.shouldShowResultsStep) {
            [self showAlert:NSLocalizedString(@"There are missing answers from the previous step.", @"There are missing answers from the previous step.")
                 andMessage:NSLocalizedString(@"All fields are required.", @"All fields are required.")];
            
            //Set shouldShowStep to NO so we do not show the next step.
            shouldShowStep = self.shouldShowResultsStep;
        }
        
    }
    
    return shouldShowStep;
}

//- (void)taskViewController:(ORKTaskViewController *)taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
//{
//    self.navigationBar.topItem.title = NSLocalizedString(@"Baseline Survey", @"Baseline Survey");
//}

#pragma mark - Helpers

- (void)showAlert:(NSString *)title andMessage:(NSString*)message
{
    UIAlertController* alerVC = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"OK",
                                                           @"OK")
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * __unused action) {
                             [alerVC dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    
    [alerVC addAction:ok];
    
    [self presentViewController:alerVC animated:NO completion:nil];
    
}

- (BOOL)questionStepResultFieldsAreComplete:(NSString *)stepIdentifier title:(NSString **)title message:(NSString **)message {
    
    BOOL noPass = NO;
    
    ORKStepResult *stepResult = [self.result stepResultForStepIdentifier:stepIdentifier];
    
    NSArray *questionsFields = stepResult.results;
    
    for (ORKQuestionResult *questionResult in questionsFields) {
        
        if (questionResult.questionType == ORKQuestionTypeInteger) {
            ORKNumericQuestionResult *medicationDose = (ORKNumericQuestionResult *)questionResult;
            
            if ([medicationDose.numericAnswer integerValue] <= 0) {
                *title = NSLocalizedString(@"Invalid Dose", @"Invalid Dose");
                NSString *doseValue = [NSString stringWithFormat:@"%lu is not a valid value for the medication dose. Please enter a valid dose value.", (long)[medicationDose.numericAnswer integerValue]];
                *message = NSLocalizedString(doseValue,
                                             @"{value} is not a valid value for the medication dose. Please enter a valid dose value.");
                noPass = YES;
                break;
            }
        } else if (questionResult.questionType == ORKQuestionTypeText) {
            ORKTextQuestionResult *medicationName = (ORKTextQuestionResult *)questionResult;
            NSString *medName = [medicationName.textAnswer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if ([medName length] < 1) {
                *title = NSLocalizedString(@"Invalid Medication Name", @"Invalid Medication Name");
                NSString *medNameValue = [NSString stringWithFormat:@"%@ is not a valid medication name. Please enter a valid medication name.", medName];
                *message = NSLocalizedString(medNameValue, @"{medication name} is not a valid medication name. Please enter a valid medication name.");
                noPass = YES;
                break;
            }
        }
    }
    
    return !noPass ? YES : NO;
}

@end
