//
//  ControllerFatEstimator.h
//  Fat_Estimation
//
//  Created by Long Pun on 23/08/13.
//
//

#import <AppKit/AppKit.h>

@class Fat_EstimationFilter;

@interface ControllerFatEstimator : NSWindowController
{
    IBOutlet NSTextField *total_area;
    IBOutlet NSTextField *rmean;
    IBOutlet NSTextField *rdev;
//    IBOutlet NSTextField *rskew;
    IBOutlet NSTextField *rmin;
    IBOutlet NSTextField *rmax;
    
    IBOutlet NSTextField *fcsa_otsu;
    IBOutlet NSTextField *muscle_area_otsu;
    IBOutlet NSTextField *fat_content_otsu;
    IBOutlet NSTextField *fat_area_otsu;
    IBOutlet NSTextField *fcsa_met;
    IBOutlet NSTextField *muscle_area_met;
    IBOutlet NSTextField *fat_content_met;
    IBOutlet NSTextField *fat_area_met;
    IBOutlet NSTextField *thres_otsu;
    IBOutlet NSTextField *thres_met;
    IBOutlet NSTextField *J_met;//for met
    
    Fat_EstimationFilter *filter;
    DCMPix *pix;
    ROI *curROI;
    NSButton *display_my_log;
}


- (id) init: (Fat_EstimationFilter*) f;
- (void) biascorrect: (Fat_EstimationFilter*) f;
- (void)compute;//compute fsca,etc
- (IBAction)update:(id)sender;
@end
