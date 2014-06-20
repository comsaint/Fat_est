//
//  Fat_EstimationFilter.h
//  Fat_Estimation
//
//  Copyright (c) 2013 Long. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>


@interface Fat_EstimationFilter : PluginFilter {
    
}
- (long) filterImage:(NSString*) menuName;
- (ViewerController*) viewerController;

@end