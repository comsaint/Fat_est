//
//  Fat_EstimationFilter.m
//  Fat_Estimation
//
//  Copyright (c) 2013 Long. All rights reserved.
//

#import "Fat_EstimationFilter.h"
#import "ControllerFatEstimator.h"

@implementation Fat_EstimationFilter

- (ViewerController*) viewerController
{
    return viewerController;
}


- (long) filterImage:(NSString*) menuName
{
    ControllerFatEstimator* coWin = [[ControllerFatEstimator alloc] init:self];
    [coWin showWindow:self];
    
    return 0;
}

@end
    /*
     
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
     
     
     
    //Get the current slice and pixel
    NSMutableArray *pixList = [viewerController pixList: 0];
    int curSlice = [[viewerController imageView] curImage];
    DCMPix *curPix = [pixList objectAtIndex:curSlice];
    
    //Get the first roi of the current image inside current 2DViewer
    //TODO: change it to user select
    NSMutableArray *roiSeriesList = [viewerController roiList];
    NSMutableArray *roiImageList = [roiSeriesList objectAtIndex:curSlice];
    
    //The first ROI is got...
    ROI *firstROI = [roiImageList objectAtIndex:0];
     */

