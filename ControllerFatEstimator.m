//
//  ControllerFatEstimator.m
//  Fat_Estimation
//
//  Created by Long Pun on 23/08/13.
//
//
#import "Fat_EstimationFilter.h"
#import "ControllerFatEstimator.h"

#define id Id
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkN4BiasFieldCorrectionImageFilter.h"
#include "itkOtsuThresholdImageFilter.h"
#include "itkArray.h"
#include "itkShrinkImageFilter.h"
#include "itkExtractImageFilter.h"
#undef id

#define ImageDimension 3

@class ROI;
@class ViewerController;
@class DCMPix;

@implementation ControllerFatEstimator

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib
{
	NSLog( @"Nib loaded!");
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(closeViewer:)
               name: @"CloseViewerNotification"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiChange"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"removeROI"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiSelected"
             object: nil];
}

- (id) init:( Fat_EstimationFilter*) f
{
    self = [super initWithWindowNibName:@"ControllerFatEstimator"];
    
	//[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
    
    /*
	if(!self){NSRunInformationalAlertPanel(@"Hell", @"I don't know", @"Damn!", nil, nil);}
    else {NSRunInformationalAlertPanel(@"Yeah", @"I know", @"OK", nil, nil);};
	*/
    
    [self showWindow:self];
    
    filter = f;
    //[self biascorrect:filter];
    
    
    //Get the roi
    NSMutableArray		*roiSeriesList = [[f viewerController]roiList];
    int curslice = [[[f viewerController] imageView]curImage];
    NSMutableArray *roiImageList = [roiSeriesList objectAtIndex :curslice];
    
    // Get the pixels
    NSArray *PixList = [[f viewerController]pixList];
    pix = [PixList objectAtIndex:curslice];
    
    
    for (int i=0; i<[roiImageList count];i++)
    {
        curROI = [roiImageList objectAtIndex: i];
        if( [curROI ROImode] == ROI_selected || [curROI ROImode] == ROI_selectedModify)
        {
            
            [self compute];
            break;
        }
    }
    [self showWindow:self];
    
    return 0;
}

//N4BiasFieldCorrection

- (void)biascorrect:( Fat_EstimationFilter*) f
{
    typedef     float itkPixelType;
    typedef     itk::Image< itkPixelType, ImageDimension > ImageType;
    typedef     itk::ImportImageFilter< itkPixelType, ImageDimension > ImportFilterType;
    typedef typename ImageType::Pointer ImagePointer;
    
    
    DCMPix      *firstPix = [[[f viewerController] pixList] objectAtIndex:0];
    int         slices = [[[f viewerController] pixList] count];
    long        bufferSize;
    
    ImportFilterType::Pointer       importFilter = ImportFilterType::New();
    ImportFilterType::SizeType      size;
    ImportFilterType::IndexType     start;
    ImportFilterType::RegionType    region;
    
    start.Fill(0);
    
    size[0] = [firstPix pwidth];
    size[1] = [firstPix pheight];
    size[2] = slices;
    
    bufferSize = size[0] * size[1] * size[2];
    
    double  origin[3];
    double  originConverted[ 3];
    double  vectorOriginal[ 9];
    double  voxelSpacing[3];
    
    origin[0] = [firstPix originX];
    origin[1] = [firstPix originY];
    origin[2] = [firstPix originZ];
    
    [firstPix orientationDouble: vectorOriginal];
    originConverted[ 0] = origin[ 0] * vectorOriginal[ 0] + origin[ 1] * vectorOriginal[ 1] + origin[ 2] * vectorOriginal[ 2];
    originConverted[ 1] = origin[ 0] * vectorOriginal[ 3] + origin[ 1] * vectorOriginal[ 4] + origin[ 2] * vectorOriginal[ 5];
    originConverted[ 2] = origin[ 0] * vectorOriginal[ 6] + origin[ 1] * vectorOriginal[ 7] + origin[ 2] * vectorOriginal[ 8];
    
    voxelSpacing[0] = [firstPix pixelSpacingX];
    voxelSpacing[1] = [firstPix pixelSpacingY];
    voxelSpacing[2] = [firstPix sliceInterval];
    
    region.SetIndex(start);
    region.SetSize(size);
    
    importFilter->SetRegion(region);
    importFilter->SetOrigin(originConverted);
    importFilter->SetSpacing(voxelSpacing);
    importFilter->SetImportPointer([[f viewerController] volumePtr] , bufferSize, false);
    ImagePointer inputImage = importFilter->GetOutput();
    //The image is now imported to ITK as inputImage.
    
 
     //N4BiasCorrection - workflow:
     //1. Create a mask.
     //2. Shrink the inputImage (as well as mask) down to reduce computation time (significantly).
     //3. Run bias correction.
     //4. Recover the bias field after bias correction.
     //5. Divide inputImage by the bias field to get the output image.
     //6. Make the size of output image identical to inputImage (otherwise Osirix will crash!)
 
    
    
    //1. Create Otsu mask
    typedef itk::Image<unsigned char, ImageDimension> MaskImageType;
    typedef typename MaskImageType::Pointer MaskImagePointer;
    
    typedef itk::OtsuThresholdImageFilter<ImageType,MaskImageType> ThresholdType;
    typename ThresholdType::Pointer otsu = ThresholdType::New();
    typename MaskImageType::Pointer maskImage = NULL;
    typename ImageType::Pointer outImage = NULL;
    
    otsu->SetInput(importFilter->GetOutput());
    otsu->SetNumberOfHistogramBins(200);
    otsu->SetInsideValue(0);
    otsu->SetOutsideValue(1);
    otsu->Update();
    maskImage = otsu->GetOutput();
    maskImage->DisconnectPipeline();
    //Done with mask creation
    
    
    
    
    //Instantiate and Set some parameters for biascorrectionFilter
    typedef itk::N4BiasFieldCorrectionImageFilter<ImageType, MaskImageType, ImageType> N4BiasFieldCorrectionImageFilterType;
    N4BiasFieldCorrectionImageFilterType::Pointer biascorrectionFilter = N4BiasFieldCorrectionImageFilterType::New();
    
    //These parameters can be changed:
    unsigned int iterlevel = 3;
    biascorrectionFilter->SetNumberOfFittingLevels(iterlevel);
    N4BiasFieldCorrectionImageFilterType::VariableSizeArrayType maxiterary(iterlevel);
    //Remember to change these as well
    maxiterary[0]=100;
    maxiterary[1]=50;
    maxiterary[2]=50;
    
    biascorrectionFilter->SetMaximumNumberOfIterations(maxiterary);
    biascorrectionFilter->SetConvergenceThreshold(0.0001);
    biascorrectionFilter->SetMaskLabel(1);//Make sure this is the same as specified in the mask
    biascorrectionFilter->SetBiasFieldFullWidthAtHalfMaximum(0.15);
    biascorrectionFilter->SetSplineOrder(3);
    biascorrectionFilter->SetWienerFilterNoise(0.01);
    //End of parameters
    
    
    
    //2. Shrink (original) image to decrease computation time
    unsigned int shrink_factor = 4;//This can be changed
    
    typedef itk::ShrinkImageFilter<ImageType, ImageType> ShrinkImageFilterType;
    typename ShrinkImageFilterType::Pointer shrinker =ShrinkImageFilterType::New();
    shrinker->SetInput(inputImage);
    shrinker->SetShrinkFactors(shrink_factor);
    
    
    //Shrink (mask) image as well
    typedef itk::ShrinkImageFilter<MaskImageType, MaskImageType> MaskShrinkImageFilterType;
    typename MaskShrinkImageFilterType::Pointer maskshrinker = MaskShrinkImageFilterType::New();
    maskshrinker->SetInput(maskImage);
    maskshrinker->SetShrinkFactors(shrink_factor);
    
    
    //Execute shrinking
    shrinker->Update();
    maskshrinker->Update();
    
    ImagePointer shrinkinputImage = shrinker->GetOutput();
    MaskImagePointer shrinkmaskImage = maskshrinker->GetOutput();
    
    
    
    
    //3. Set inputs of the biascorrectionFilter, and execute
    biascorrectionFilter->SetInput(shrinkinputImage);
    biascorrectionFilter->SetMaskImage(shrinkmaskImage);
    biascorrectionFilter->Update();
    
    
    //4. Recover the bias field
 
    //Reconsruct the bias field at full image resoluion.  Divide
    //the original input image by the bias field to get the final
    //corrected image.

 
    typedef itk::BSplineControlPointImageFilter<N4BiasFieldCorrectionImageFilterType::BiasFieldControlPointLatticeType,N4BiasFieldCorrectionImageFilterType::ScalarImageType> BSplinerType;
    BSplinerType::Pointer bspliner = BSplinerType::New();
    
    ImageType::IndexType inputImageIndex =
    inputImage->GetLargestPossibleRegion().GetIndex();
    ImageType::SizeType inputImageSize =
    inputImage->GetLargestPossibleRegion().GetSize();
    
    ImageType::PointType newOrigin = inputImage->GetOrigin();
    bspliner->SetInput( biascorrectionFilter->GetLogBiasFieldControlPointLattice() );
    bspliner->SetSplineOrder( biascorrectionFilter->GetSplineOrder() );
    bspliner->SetSize( inputImage->GetLargestPossibleRegion().GetSize() );
    bspliner->SetOrigin( newOrigin );
    bspliner->SetDirection( inputImage->GetDirection() );
    bspliner->SetSpacing( inputImage->GetSpacing() );
    bspliner->Update();
    
    ImageType::Pointer logField = ImageType::New();
    logField->SetOrigin( inputImage->GetOrigin() );
    logField->SetSpacing( inputImage->GetSpacing() );
    logField->SetRegions( inputImage->GetLargestPossibleRegion() );
    logField->SetDirection( inputImage->GetDirection() );
    logField->Allocate();
    
    itk::ImageRegionIterator<N4BiasFieldCorrectionImageFilterType::ScalarImageType> IB(
                                                                                       bspliner->GetOutput(),
                                                                                       bspliner->GetOutput()->GetLargestPossibleRegion() );
    itk::ImageRegionIterator<ImageType> IF( logField,
                                           logField->GetLargestPossibleRegion() );
    for( IB.GoToBegin(), IF.GoToBegin(); !IB.IsAtEnd(); ++IB, ++IF )
    {
        IF.Set( IB.Get()[0] );
    }
    
    
    //Exponential
    typedef itk::ExpImageFilter<ImageType, ImageType> ExpFilterType;
    ExpFilterType::Pointer expFilter = ExpFilterType::New();
    expFilter->SetInput( logField );
    expFilter->Update();
    
    
    
    //5. Get the output image by dividing inputInage by bias field
    typedef itk::DivideImageFilter<ImageType, ImageType, ImageType> DividerType;
    DividerType::Pointer divider = DividerType::New();
    divider->SetInput1( inputImage );
    divider->SetInput2( expFilter->GetOutput() );
    divider->Update();
    
    
    
    //6. Adjust output image size by cropper
    //Crop the image
    ImageType::RegionType inputRegion;
    inputRegion.SetIndex( inputImageIndex );
    inputRegion.SetSize( inputImageSize );
    typedef itk::ExtractImageFilter<ImageType, ImageType> CropperType;
    CropperType::Pointer cropper = CropperType::New();
    cropper->SetInput( divider->GetOutput() );
    cropper->SetExtractionRegion( inputRegion );
    cropper->SetDirectionCollapseToSubmatrix();
    cropper->Update();
    
    
    
    //Output
    float* resultBuff = cropper->GetOutput()->GetBufferPointer();
    
    
    long mem = bufferSize * sizeof(float);
    memcpy( [[f viewerController] volumePtr], resultBuff, mem);
    
    [[f viewerController] needsDisplayUpdate];
}



- (void)compute
{
    long count=0;
    float mean=0,dev=0,min=0,max=0;
    //double skewness,kurtosis;//maybe implement later
    float** loc=nil;
    
    float *values = [pix getROIValue: &count :curROI :loc];
    
    [pix computeROI:curROI
                    :&mean
                    :nil    //total sum not necessary
                    :&dev
                    :&min
                    :&max
     ];
    
    //Make a custom histogram (necessary?)
    //Define number of bins by (total sample size)^(1/3) [a rule of thumb]
    //int num_bin = round(pow(total,1/3));
    
    //Or maybe 255 bins?
    int num_bin = 255;
    
    //the easiest way to normalize is to standardise the ROI to [0,255]
    //can add different things later, e.g. various bin number, outlier removal, etc.
    
    //linear scaling
    for (int i = 0;i<count;i++){
        values[i] = (values[i]-min)/(max-min) * num_bin;
    }
    
    double *myhistogram = (double*)calloc(num_bin, sizeof(double));
    //Initialize: just in case...
    for (int i =0;i<num_bin;i++){
        myhistogram[i]=0;
    }
    
    //Put values into bins
    for (int i=0;i<count;i++){
        for (int j=0;j<num_bin;j++){
            if (values[i]>=j && values[i]<j+1) {
                myhistogram[j]=myhistogram[j]+1;
                //break;
            }
        }//can be rewritten into a while loop
    }
    //Moto of engineering: if it is not broken, don't fix it.
    
    
    // normalize the histogram
    for (int i=0;i<num_bin;i++){
        myhistogram[i]=(double) myhistogram[i]/count;
    }
    
    //Testing: arbitrary histogram
    /*
    for (int i=0;i<127;i++){
        myhistogram[i] = 0.25/127;
    }
    for (int i=127;i<255;i++){
        myhistogram[i] = 0.75/128;
    }
    */
    //Another go on Otsu and MET
    double P1=0,P2=1;//class prob.
    double mean1=0,mean2=0; //class means
    double sigma1=0,sigma2=0;//class variances
    double obj_otsu[num_bin],obj_met[num_bin];//note that the first and last index are unused => be careful when searching for min and max

    for (int t=1; t<num_bin-1; t++) {
        mean1=0;mean2=0;sigma1=0;sigma2=0;
        
        P1 += myhistogram[t];
        P2 = 1.0-P1;
        
        //class mean
        for (int i=0; i<t; i++) {
            mean1 += i*myhistogram[i]/P1;
        }
        for (int i=t; i<num_bin; i++) {
            mean2 += i*myhistogram[i]/P2;
        }
        
        //class variance (note they are squared sd)
        for (int i=0; i<t; i++){
            sigma1 += pow((double)(i-mean1),2)*myhistogram[i]/P1;
        }
        for (int i=t; i<num_bin; i++){
            sigma2 += pow((double)(i-mean2),2)*myhistogram[i]/P2;
        }
        
        //Otsu's objective function
        obj_otsu[t]=pow(mean1-mean2,2)*(P1*P2);
        
        //MET objective function
        obj_met[t]=1+2*(P1*log(sqrt(sigma1))+P2*log(sqrt(sigma2)))-2*(P1*log(P1)+P2*log(P2));
    }
    
    //Search for threshold
    // note Otsu search for max while MET search for min
    double tmp_otsu,tmp_met;
    int idx_otsu = 1, idx_met = 1;
    
    //Init
    int tmp_idx = 1;
    while (!finite(obj_otsu[tmp_idx])) {
        tmp_idx++;
    }tmp_otsu = obj_otsu[tmp_idx];
    
    tmp_idx = 1;
    while (!finite(obj_met[tmp_idx])) {
        tmp_idx++;
    }tmp_met = obj_met[tmp_idx];
    
    for (int t=1; t<num_bin-1;t++){
        if(finite(obj_otsu[t]) && obj_otsu[t]>tmp_otsu){
            tmp_otsu = obj_otsu[t];
            idx_otsu = t;
        }
        if(finite(obj_met[t]) && obj_met[t]<tmp_met){
            tmp_met = obj_met[t];
            idx_met = t;
        }
    }
    
    // Convert back to image space
    double threshold_otsu = idx_otsu;
    double threshold_met = idx_met;
    
    //after that it is all about FCSA, etc.
    //first, calculate fcsa for each method
    
    //note that everything here has been scaled to [0,255]
    //if we want to map back to image space we need to use
    // val = val/255*(max-min) + min
    
    double temp_fcsa_otsu=0,temp_fcsa_met=0;
    
    // Old method
    for (int i=0; i<count; i++) {
        if (values[i]<threshold_otsu) {
            temp_fcsa_otsu=temp_fcsa_otsu+1;
        }
        if (values[i]<threshold_met) {
            temp_fcsa_met=temp_fcsa_met+1;
        }
    }
    //
    
    temp_fcsa_otsu = (double)temp_fcsa_otsu/count*100;//in percent
    temp_fcsa_met = (double)temp_fcsa_met/count*100;
    
    //calculate fat content
    double temp_fat_otsu = 100-temp_fcsa_otsu;
    double temp_fat_met = 100-temp_fcsa_met;
    
    // double ROI area
    double ttl_area = [curROI roiArea];
    
    //calculate muscle area
    double temp_muscle_area_otsu = ttl_area*(temp_fcsa_otsu/100);
    double temp_muscle_area_met = ttl_area*(temp_fcsa_met/100);
    //and fat area
    double temp_fat_area_otsu = ttl_area - temp_muscle_area_otsu;
    double temp_fat_area_met = ttl_area - temp_muscle_area_met;
    
    //Make the number look nicer...
    //Do not want to play with NSNumberFormatter, so use the silly way
    ttl_area=[[NSString stringWithFormat:@"%.3f",ttl_area]doubleValue];
    
    //something is wrong with these pointers...
    //mean=[[NSString stringWithFormat:@"%.3f",mean]doubleValue];
    //dev=[[NSString stringWithFormat:@"%.3f",dev]doubleValue];
    
    temp_fcsa_otsu=[[NSString stringWithFormat:@"%.2f",temp_fcsa_otsu]doubleValue];
    temp_fcsa_met=[[NSString stringWithFormat:@"%.2f",temp_fcsa_met]doubleValue];
    
    temp_fat_otsu=[[NSString stringWithFormat:@"%.2f",temp_fat_otsu]doubleValue];
    temp_fat_met=[[NSString stringWithFormat:@"%.2f",temp_fat_met]doubleValue];
    
    temp_fat_area_otsu=[[NSString stringWithFormat:@"%.2f",temp_fat_area_otsu]doubleValue];
    temp_fat_area_met=[[NSString stringWithFormat:@"%.2f",temp_fat_area_met]doubleValue];
    
    temp_muscle_area_otsu=[[NSString stringWithFormat:@"%.2f",temp_muscle_area_otsu]doubleValue];
    temp_muscle_area_met=[[NSString stringWithFormat:@"%.2f",temp_muscle_area_met]doubleValue];
    
    //And convert the threshold back to image space
    threshold_otsu = threshold_otsu/num_bin*(max-min)+min;
    threshold_met = threshold_met/num_bin*(max-min)+min;
    //done with calculations! display output in panel
    [self->total_area setDoubleValue:ttl_area];
    [self->rmean setDoubleValue:mean];
    [self->rdev setDoubleValue:dev];
    [self->rmin setDoubleValue:min];
    [self->rmax setDoubleValue:max];
    
    [self->fcsa_otsu setDoubleValue:temp_fcsa_otsu];
    [self->muscle_area_otsu setDoubleValue:temp_muscle_area_otsu];
    [self->fat_content_otsu setDoubleValue:temp_fat_otsu];
    [self->fat_area_otsu setDoubleValue:temp_fat_area_otsu];
    [self->thres_otsu setIntValue:threshold_otsu];
    
    [self->fcsa_met setDoubleValue:temp_fcsa_met];
    [self->muscle_area_met setDoubleValue:temp_muscle_area_met];
    [self->fat_content_met setDoubleValue:temp_fat_met];
    [self->fat_area_met setDoubleValue:temp_fat_area_met];
    [self->thres_met setIntValue:threshold_met];
    //[self->J_met setDoubleValue:obj_met[idx_met]];
    //NSRunInformationalAlertPanel(@"Done", @"At least I was run...", @"Ease...", nil, nil);
    
    //TODO:
    //Finally, try to color the pixels above some threshold
    
    //backup the original image
    //DCMPix *backup_img = malloc(sizeof(pix));//but how to copy all values?

    long curPos;
    //float* tmp_pos = NULL;
    long textWidth = [pix pwidth];
    float *fImage;
    
    fImage = [pix fImage];
    for (int i=0; i<count; i++) {
        if (values[i]>threshold_met) {
            //curPos = (*loc[i*2])+ (*loc[i*2+1])*textWidth;
            
            //[pix convertPixX:*loc[i*2] pixY:*loc[i*2+1] toDICOMCoords:tmp_pos pixelCenter: NO];
            //curPos = *tmp_pos;
            //fImage[curPos] = 1024;
            break;
        }
    }
    
    
    [[filter viewerController] needsDisplayUpdate];
  
}

- (IBAction)update:(id)sender
{
    [self init:filter];
}

- (void) closeViewer :(NSNotification*) note
{
	if( [note object] == [filter viewerController])
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		[self autorelease];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[self autorelease];
}

- (void) dealloc
{
	[curROI release];
	curROI = 0L;
    
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

@end

