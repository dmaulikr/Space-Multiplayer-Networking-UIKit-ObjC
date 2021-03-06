//
//  BuildingBuildView.m
//  space
//
//  Created by Martin Walsh on 29/10/2012.
//  Copyright (c) 2012 Pedro LTD. All rights reserved.
//

#import "BuildingBuildView.h"
#import "GameManager.h"
#import "UILabel+formatHelpers.h"
#import "BuildingSelectionTableViewController.h"

#define DEFAULT_BUILD_AMOUNT    1
#define DEFAULT_BUILD_DEPTH     1

@implementation BuildingBuildView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Initialization From NIB
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if(self) {
        _amount = DEFAULT_BUILD_AMOUNT;
        _depth  = DEFAULT_BUILD_DEPTH;
    }
    return self;
}


-(void) setup:(int) buildingID
{

    NSDictionary* buildingDict = [[GameManager sharedInstance] getBuilding:buildingID];
    NSDictionary* planetDict   = [[[GameManager sharedInstance] planetDict] objectForKey:@"planet"];
        
    // Setup Stepper Amount
    _stepperAmount.maximumValue = [[planetDict objectForKey:@"build_max"] intValue];
    _stepperAmount.minimumValue = 1;
    _stepperAmount.value        = _amount;
    _stepperAmount.stepValue    = 1;
    
    _stepperDepth.maximumValue = [[planetDict objectForKey:@"build_queue"] intValue];
    _stepperDepth.minimumValue = 1;
    _stepperDepth.value        = _depth;
    _stepperDepth.stepValue    = 1;
    
    // Modify Button
    UIImage *buttonImage = [[UIImage imageNamed:@"blueButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    [_button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    
    // Store Dictionary
    _buildingDict = [NSDictionary dictionaryWithDictionary:buildingDict];
    
    // Basic Outlets
    _buildingName.text        = [buildingDict objectForKey:@"name"];
    
    // Building ID
    _building_id = [[buildingDict objectForKey:@"id"] intValue];
    
    // Load Icon
    if([buildingDict objectForKey:@"image"]!=[NSNull null])
    {
        [_buildingIcon setImage:[UIImage imageNamed:[buildingDict objectForKey:@"image"]]];
    }
    
    // Dynamic Updates
    [self updateAmount];
    
    self.alpha = 0.0f;
    [UIView animateWithDuration:0.25f
                          delay:0.0f
                        options: UIViewAnimationCurveLinear
                     animations:^{
                         self.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                     }];
}

-(void) updateAmount
{
    // Number Formatter
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    // Build Time
    double buildTime = _itemTime;
    buildTime*=_amount;
    buildTime*=_depth;
    [_buildingTime setTimerText:[NSNumber numberWithDouble:buildTime]];
    
    int value = 0;
    
    // Costs
    NSDictionary* costDict = [_buildingDict objectForKey:@"cost"];
    
    // Set Cost / Incomes
    // Food
    value = [[costDict objectForKey:@"food"] intValue];
    value*=_amount;
    [_buildingCostFood setTextNegativeRate:[NSNumber numberWithInt:value]];
    // Workers
    value = [[costDict objectForKey:@"workers"] intValue];
    value*=_amount;
    [_buildingCostWorkers setTextNegativeRate:[NSNumber numberWithInt:value]];
    // Energy
    value = [[costDict objectForKey:@"energy"] intValue];
    value*=_amount;
    [_buildingCostEnergy setTextNegativeRate:[NSNumber numberWithInt:value]];
    // Minerals
    value = 0;
    value*=_amount;
    [_buildingCostMinerals setTextNegativeRate:[NSNumber numberWithInt:value]];
    
  
    
    NSDictionary* incomeDict = [_buildingDict objectForKey:@"income"];
    
    // Set Rates
    // Food
    value = [[incomeDict objectForKey:@"food"] intValue];
    value*=_amount;
    [_buildingRateFood setTextRate:[NSNumber numberWithInt:value]];
    
    // Workers
    value = [[incomeDict objectForKey:@"workers"] intValue];
    value*=_amount;
    [_buildingRateWorkers setTextRate:[NSNumber numberWithInt:value]];
    
    // Energy
    value = [[incomeDict objectForKey:@"energy"] intValue];
    value*=_amount;
    [_buildingRateEnergy setTextRate:[NSNumber numberWithInt:value]];
    
    // Minerals
    value = [[incomeDict objectForKey:@"minerals"] intValue];
    value*=_amount;
    [_buildingRateMinerals setTextRate:[NSNumber numberWithInt:value]];

    // Rate Multiplier
    _buildingRateAmount.text = [NSString stringWithFormat:@"x%d",_amount];
    _buildingRateDepth.text = [NSString stringWithFormat:@"x%d",_depth];
    
}

#pragma mark UI Action Controls
- (IBAction) stepperValueChanged:(id)sender
{
    _amount = _stepperAmount.value;
    [self updateAmount];
}

- (IBAction) stepperValueDepthChanged:(id)sender
{
    _depth = _stepperDepth.value;
    [self updateAmount];
}

-(IBAction) buttonPressed:(id)sender
{
    [self lockUI];
    
    [[GameManager sharedInstance] addBuilding:_building_id setAmount:_amount setDepth:_depth setPlanet:[[GameManager sharedInstance] planetID]  setBlock:^(NSDictionary *jsonDict){
        
        double time = [[[jsonDict objectForKey:@"build"] objectForKey:@"end_time"] doubleValue];
        // Format Time
        // Date Formatter from Unix Timestamp
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss"];
        
        [[TKAlertCenter defaultCenter] postAlertWithMessage:[NSString stringWithFormat:@"Building Added to Queue\n ETA: %@",[dateFormat stringFromDate:date]]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"buildingRefresh" object:self];
        
        // Set Notification
        [[GameManager sharedInstance] createNotification:time setMessage:[NSString stringWithFormat:@"%dx%d %@ Build Complete",_depth,_amount,_buildingName.text]];
        
        // Dismiss
        [[GameManager sharedInstance] dismissPopup:nil];
        
    } setBlockFail:^(){
        [self unlockUI];
    }];

}

-(void) lockUI
{
    [_button setUserInteractionEnabled:NO];
    [_stepperAmount setUserInteractionEnabled:NO];
    [_stepperDepth setUserInteractionEnabled:NO];
}

-(void) unlockUI
{
    [_button setUserInteractionEnabled:YES];
    [_stepperAmount setUserInteractionEnabled:YES];
    [_stepperAmount setUserInteractionEnabled:NO];
}


@end
