// 
//  APHDashboardEditViewController.m 
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
 
#import "APHDashboardEditViewController.h"

@implementation APHDashboardEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareData];
}

- (void)prepareData
{
    [self.items removeAllObjects];
    
    {
        for (NSNumber *typeNumber in self.rowItemsOrder) {
            
            APHDashboardItemType rowType = typeNumber.integerValue;
            
            switch (rowType) {
                case kAPHDashboardItemTypeSteps:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Steps", @"");
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeGlucose:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Glucose", @"");
                    item.taskId = @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15";
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                case kAPHDashboardItemTypeWeight:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.taskId = @"APHEnterWeight-76C03691-4417-4AD6-8F67-F708A8897FF6";
                    item.caption = NSLocalizedString(@"Weight", @"");
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypeCarbohydrate:
                {
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Carbohydrates", @"");
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    
                    [self.items addObject:item];
                }
                    break;
                
                case kAPHDashboardItemTypeSugar:
                {
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Sugar", @"");
                    item.tintColor = [UIColor appTertiaryBlueColor];
                    
                    [self.items addObject:item];
                }
                    break;
                
                case kAPHDashboardItemTypeCalories:
                {
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Calories", @"");
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    [self.items addObject:item];
                }
                    break;

                case kAPHDashboardItemTypeFitness:
                {
                    if ([APCDeviceHardware isiPhone5SOrNewer]) {
                        APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                        item.caption = NSLocalizedString(@"Activity Tracker", @"");
                        item.tintColor = [UIColor appTertiaryBlueColor];
                        
                        [self.items addObject:item];
                    }
                }
                    break;
                
                case kAPHDashboardItemTypeGlucoseInsights:
                {
                    NSString *glucoseLevels = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser.glucoseLevels;
                    
                    if (glucoseLevels) {
                        APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                        item.caption = NSLocalizedString(@"Glucose Insights", @"");
                        item.tintColor = [UIColor appTertiaryBlueColor];
                        
                        [self.items addObject:item];
                    }
                }
                    break;
                
                    
                case kAPHDashboardItemTypeDietInsights:
                {
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Diet Insights", @"");
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    [self.items addObject:item];
                }
                    break;
                
                default:
                    break;
            }
        }
        
    }
}

@end
