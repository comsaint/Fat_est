//
//  ControllerFatEstimatorViewController.m
//  Fat_Estimation
//
//  Created by Long Pun on 23/08/13.
//
//

#import "ControllerFatEstimatorViewController.h"

@interface ControllerFatEstimatorViewController ()

@end

@implementation ControllerFatEstimatorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end

//
//  FatEstimator.m
//  Fat_Estimation
//
//  Created by Long Pun on 23/08/13.
//
//
#include "math.h"

#import "ControllerFatEstimator.h"
#import "Fat_EstimationFilter.h"

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

//#import "ViewerController.h"

@implementation ControllerFatEstimator

-(IBAction)compute:(id)sender
{
    
    //What to do with it?
    //1. Get all the pixel values
    long count=0;
    float *values = [curPix getROIValue: &count :firstROI :nil];//'values' is an array of all intensity values
    
    //check
    if(values==nil){
        NSRunInformationalAlertPanel(@"values pointer not allocated", @"Error!", @"OK", nil, nil);
    }
    
    else{
        NSRunInformationalAlertPanel(@"So far so good", @"I want to print!...", @"OK", nil, nil);
    }
    
    
    //2. Compute histogram
    
    
    
    //For fun
    //NSRunInformationalAlertPanel(@"So far so good", @"I can run up to this point", @"OK", nil, nil);
}

- (id) init:(Fat_EstimationFilter*) f
{
    self = [super initWithWindowNibName:@"ControllerFatEstimator"];
    
    [[self window] setDelegate:self];
    
    filter = f;
    
    NSMutableArray *roiSeriesList, *roiImageList;
    
    //Find the selected roi on current viewer
    NSMutableArray *pixList = [viewerController pixList: 0];
}

- (ViewerController*) viewerController
{
    return viewerController;
}
@end
