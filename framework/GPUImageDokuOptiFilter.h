//
//  GPUImageDokuOptiFilter.h
//  GPUImage
//
//  Created by Martin Stämmler on 09.08.13.
//  Copyright (c) 2013 Brad Larson. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

@interface GPUImageDokuOptiFilter : GPUImageTwoInputFilter
{
    GLint offsetUniform;
}

// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2), with 0.5 (half of either) as the normal level
@property(readwrite, nonatomic) CGFloat offset;





@end
