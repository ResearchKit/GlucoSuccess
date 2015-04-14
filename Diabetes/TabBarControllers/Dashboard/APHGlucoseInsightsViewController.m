// 
//  APHGlucoseInsightsViewController.m 
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
 
#import "APHGlucoseInsightsViewController.h"
#import "APHAppDelegate.h"

static NSString *kInsightCellIdentifier = @"APCDashboardInsightTableViewCell";
static NSString *kInsightSummaryHeaderCellIdentifier = @"APCDashboardInsightSummaryHeaderTableViewCell";
static NSString *kInsightSummaryCellIdentifier = @"APCDashboardInsightSummaryTableViewCell";
static NSString *kInsightNoDataIsAvailable = @"Not enough data";

static NSUInteger caloriesPerGramOfCarbsAndSugar = 4;

static NSNumberFormatter *numberFormatter = nil;

typedef NS_ENUM(NSUInteger, APHInsightRows)
{
    APHInsightRowCalories = 0,
    APHInsightRowSteps,
    APHInsightRowSugarCalories,
    APHInsightRowCarbs,
    APHInsightRowCarbsCalories,
    APHInsightTotalNumberOfRows
};

typedef NS_ENUM(NSUInteger, APHInsightSummaryRows)
{
    APHInsightSummaryRowHeader = 0,
    APHInsightSummaryRowCalories,
    APHInsightSummaryRowSteps,
    APHInsightSummaryRowSugar,
    APHInsightSummaryRowCarbohydrates,
    APHInsightSummaryTotalNumberOfRows
};

typedef NS_ENUM(NSUInteger, APHInsightSections)
{
    APHInsightSectionInsights = 0,
    APHInsightSectionSummary,
    APHInsightTotalNumberOfSections
};

@interface APHGlucoseInsightsViewController()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) APHAppDelegate *appDelegate;

@end

@implementation APHGlucoseInsightsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setMaximumFractionDigits:0];
        [numberFormatter setRoundingMode:NSNumberFormatterRoundDown];
    }
    
    // This will trigger self-sizing rows in the tableview
    self.tableView.estimatedRowHeight = 90.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}


#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return APHInsightTotalNumberOfSections;
}


- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    if (section == APHInsightSectionInsights) {
        rows = APHInsightTotalNumberOfRows;
    } else {
        rows = APHInsightSummaryTotalNumberOfRows;
        
        if (self.caloriesInsight.valueGood.doubleValue == 0) {
            rows--;
        }
        
        if (self.carbsInsight.valueGood.doubleValue == 0) {
            rows--;
        }
        
        if (self.sugarInsight.valueGood.doubleValue == 0) {
            rows--;
        }
        
        if (self.stepInsight.valueGood.doubleValue == 0) {
            rows--;
        }
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *) __unused tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == APHInsightSectionInsights) {
        cell = [self configureInsightCellAtIndexPath:indexPath];
    } else {
        cell = [self configureInsightSummaryCellAtIndexPath:indexPath];
    }
    
    return cell;
}

#pragma mark Cell Configuation

- (APCDashboardInsightTableViewCell *)configureInsightCellAtIndexPath:(NSIndexPath *)indexPath
{
    APCDashboardInsightTableViewCell *insightCell = [self.tableView dequeueReusableCellWithIdentifier:kInsightCellIdentifier
                                                                                         forIndexPath:indexPath];
    
    insightCell.tintColor = [UIColor whiteColor];
    
    switch (indexPath.row) {
        case APHInsightRowCalories:
        {
            if ([self.caloriesInsight.valueGood doubleValue] >= 1000) {
                insightCell.goodInsightCaption = self.caloriesInsight.captionGood;
                insightCell.goodInsightBar = self.caloriesInsight.valueGood;
            } else {
                insightCell.goodInsightCaption = NSLocalizedString(kInsightNoDataIsAvailable, @"Not enough data");
                insightCell.goodInsightBar = @(0);
            }
            
            if ([self.caloriesInsight.valueBad doubleValue] >= 1000) {
                insightCell.badInsightBar = self.caloriesInsight.valueBad;
                insightCell.badInsightCaption = self.caloriesInsight.captionBad;
            } else {
                insightCell.goodInsightCaption = NSLocalizedString(kInsightNoDataIsAvailable, @"Not enough data");
                insightCell.goodInsightBar = @(0);
            }
            
            insightCell.insightImage = [UIImage imageNamed:@"glucose_insights_calories"];
            
        }
            break;
        case APHInsightRowCarbsCalories:
        {
            NSString *caloriesCaption = nil;

            [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
            
            if ([self.carbsInsight.valueGood doubleValue] != 0) {
                
                NSNumber *gramsOfCarbsConsumed = self.carbsInsight.valueGood;
                NSNumber *totalNumberOfCaloriesConsumed = self.caloriesInsight.valueGood;
                double carbsCaloriesConsumed = [gramsOfCarbsConsumed doubleValue] * caloriesPerGramOfCarbsAndSugar;
                double percentOfCarbsCalories = carbsCaloriesConsumed / [totalNumberOfCaloriesConsumed doubleValue];
                
                double carbCals = (percentOfCarbsCalories < 1) ? percentOfCarbsCalories : 1;
                
                caloriesCaption = [NSString stringWithFormat:@"%@ Calories from Carbs",
                                   [numberFormatter stringFromNumber:@(carbCals)]];
                
                insightCell.goodInsightCaption = NSLocalizedString(caloriesCaption, caloriesCaption);
                insightCell.goodInsightBar = @(carbCals);
            } else {
                insightCell.goodInsightCaption = NSLocalizedString(kInsightNoDataIsAvailable, @"Not enough data");
                insightCell.goodInsightBar = @(0);
            }
            
            if ([self.carbsInsight.valueBad doubleValue] != 0) {
                NSNumber *gramsOfCarbsConsumedBad = self.carbsInsight.valueBad;
                NSNumber *totalNumberOfCaloriesConsumedBad = self.caloriesInsight.valueBad;
                double carbsCaloriesConsumedBad = [gramsOfCarbsConsumedBad doubleValue] * caloriesPerGramOfCarbsAndSugar;
                double badPercentOfCarbsCalories = carbsCaloriesConsumedBad / [totalNumberOfCaloriesConsumedBad doubleValue];
                
                double carbCals = (badPercentOfCarbsCalories < 1) ? badPercentOfCarbsCalories : 1;
                
                caloriesCaption = [NSString stringWithFormat:@"%@ Calories from Carbs",
                                   [numberFormatter stringFromNumber:@(carbCals)]];
                
                insightCell.badInsightCaption = NSLocalizedString(caloriesCaption, caloriesCaption);
                insightCell.badInsightBar = @(carbCals);
            } else {
                insightCell.goodInsightCaption = NSLocalizedString(kInsightNoDataIsAvailable, @"Not enough data");
                insightCell.goodInsightBar = @(0);
            }
            
            insightCell.insightImage = [UIImage imageNamed:@"food_insights_carbs_sugars"];
        }
            break;
        case APHInsightRowCarbs:
        {
            insightCell.goodInsightCaption = self.carbsInsight.captionGood;
            insightCell.badInsightCaption = self.carbsInsight.captionBad;
            insightCell.goodInsightBar = self.carbsInsight.valueGood;
            insightCell.badInsightBar = self.carbsInsight.valueBad;
            insightCell.insightImage = [UIImage imageNamed:@"food_insights_carbs"];
        }
            break;
        case APHInsightRowSteps:
        {
            insightCell.goodInsightCaption = self.stepInsight.captionGood;
            insightCell.badInsightCaption = self.stepInsight.captionBad;
            insightCell.goodInsightBar = self.stepInsight.valueGood;
            insightCell.badInsightBar = self.stepInsight.valueBad;
            insightCell.insightImage = [UIImage imageNamed:@"glucose_insights_steps"];
        }
            break;
        case APHInsightRowSugarCalories:
        {
            NSString *sugarCaloriesCaption = nil;

            [numberFormatter setNumberStyle:NSNumberFormatterPercentStyle];
            
            if (([self.caloriesInsight.valueGood doubleValue] != 0) &&
                ([self.caloriesInsight.valueGood doubleValue] != NSNotFound) &&
                ([self.sugarInsight.valueGood doubleValue] != 0)) {
                NSNumber *gramsOfSugarConsumed = self.sugarInsight.valueGood;
                NSNumber *totalNumberOfCaloriesConsumed = self.caloriesInsight.valueGood;
                double sugarCaloriesConsumed = [gramsOfSugarConsumed doubleValue] * caloriesPerGramOfCarbsAndSugar;
                double percentOfSugarCalories = sugarCaloriesConsumed / [totalNumberOfCaloriesConsumed doubleValue];
                
                double sugarCals = (percentOfSugarCalories < 1) ? percentOfSugarCalories : 1;
                
                sugarCaloriesCaption = [NSString stringWithFormat:@"%@ Calories from Sugar",
                                                  [numberFormatter stringFromNumber:@(sugarCals)]];
                
                insightCell.goodInsightCaption = NSLocalizedString(sugarCaloriesCaption, sugarCaloriesCaption);
                insightCell.goodInsightBar = @(sugarCals);
            } else {
                insightCell.goodInsightCaption = NSLocalizedString(kInsightNoDataIsAvailable, @"Not enough data");
                insightCell.goodInsightBar = @(0);
            }
            
            if ([self.caloriesInsight.valueBad doubleValue] != 0 &&
                ([self.caloriesInsight.valueBad doubleValue] != NSNotFound) &&
                ([self.sugarInsight.valueBad doubleValue] != 0)) {
                NSNumber *gramsOfSugarConsumedBad = self.sugarInsight.valueBad;
                NSNumber *totalNumberOfCaloriesConsumedBad = self.caloriesInsight.valueBad;
                double sugarCaloriesConsumedBad = [gramsOfSugarConsumedBad doubleValue] * caloriesPerGramOfCarbsAndSugar;
                double badPercentOfSugarCalories = sugarCaloriesConsumedBad / [totalNumberOfCaloriesConsumedBad doubleValue];
                
                double sugarCals = (badPercentOfSugarCalories < 1) ? badPercentOfSugarCalories : 1;
                
                sugarCaloriesCaption = [NSString stringWithFormat:@"%@ Calories from Sugar",
                                        [numberFormatter stringFromNumber:@(sugarCals)]];
                
                insightCell.badInsightCaption = NSLocalizedString(sugarCaloriesCaption, sugarCaloriesCaption);
                insightCell.badInsightBar = @(sugarCals);
            } else {
                insightCell.badInsightCaption = NSLocalizedString(kInsightNoDataIsAvailable, @"Not enough data");
                insightCell.badInsightBar = @(0);
            }
            
            insightCell.insightImage = [UIImage imageNamed:@"food_insights_sugars"];
        }
            break;
            
        default:
        {
            insightCell.goodInsightCaption = @"--";
            insightCell.badInsightCaption = @"--";
            insightCell.goodInsightBar = @(10);
            insightCell.badInsightBar = @(5);
        }
            break;
    }
    
    return insightCell;
}

- (APCDashboardInsightSummaryTableViewCell *)configureInsightSummaryCellAtIndexPath:(NSIndexPath *)indexPath
{
    APCDashboardInsightSummaryTableViewCell *summaryCell = nil;
    
    if (indexPath.row == APHInsightSummaryRowHeader) {
        summaryCell = [self.tableView dequeueReusableCellWithIdentifier:kInsightSummaryHeaderCellIdentifier
                                                           forIndexPath:indexPath];
        summaryCell.sidebarColor = [UIColor appTertiaryRedColor];
        summaryCell.summaryCaption = NSLocalizedString(@"Glucose Insights Summary", @"Glucose Insights Summary");
        summaryCell.showTopSeparator = YES;
    } else {
        summaryCell = [self.tableView dequeueReusableCellWithIdentifier:kInsightSummaryCellIdentifier
                                                           forIndexPath:indexPath];
        summaryCell.sidebarColor = [UIColor whiteColor];
        
        NSString *summary = nil;
        
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        
        switch (indexPath.row) {
            case APHInsightSummaryRowCalories:
            {
                if ([self.caloriesInsight.valueGood doubleValue] >= 1000) {
                    summary = [NSString stringWithFormat:@"On average, you consumed %@ calories 24-hours prior to a good glucose reading.",
                               [numberFormatter stringFromNumber:self.caloriesInsight.valueGood]];
                    summaryCell.summaryCaption = NSLocalizedString(summary, summary);
                } else {
                    summaryCell.summaryCaption = NSLocalizedString(@"Not enough data is available for showing the summary for calories.", nil);
                }
            }
                break;
            case APHInsightSummaryRowSugar:
            {
                summary = [NSString stringWithFormat:@"24 hours prior to a good glucose reading, you consumed %@ g of sugar on average.",
                           [numberFormatter stringFromNumber:self.sugarInsight.valueGood]];
                summaryCell.summaryCaption = NSLocalizedString(summary, summary);
            }
                break;
            case APHInsightSummaryRowSteps:
            {
                summary = [NSString stringWithFormat:@"On average, you took %@ steps 24-hours prior to a good glucose reading.",
                           [numberFormatter stringFromNumber:self.stepInsight.valueGood]];
                summaryCell.summaryCaption = NSLocalizedString(summary, summary);
            }
                break;
            default: // defaulting to carbs
            {
                summary = [NSString stringWithFormat:@"24 hours prior to a good glucose reading, you consumed %@ g of carbohydrates on average.",
                           [numberFormatter stringFromNumber:self.carbsInsight.valueGood]];
                summaryCell.summaryCaption = NSLocalizedString(summary, summary);
            }
                break;
        }
    }
    
    return summaryCell;
}

@end
