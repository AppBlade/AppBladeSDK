/*!
  @header APBFileMD5Hash.h
  @brief APBFileMD5Hash
 
@copyright © 2010 Joel Lopes Da Silva. All rights reserved.
@discussion
 Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#ifndef APBFILEMD5HASH_H
#define APBFILEMD5HASH_H

//---------------------------------------------------------
// Includes
//---------------------------------------------------------

// Core Foundation
#include <CoreFoundation/CoreFoundation.h>


//---------------------------------------------------------
// Constant
//---------------------------------------------------------

// In bytes
#define APBFileHashDefaultChunkSizeForReadingData 4096


//---------------------------------------------------------
// Function 
//---------------------------------------------------------
/*!
 @brief Finds hash of file. 
 @discussion A helper function that allows us to find the MD5 hash of an arbirtary file in our bundle.
 The chunk size can be changed for speed optimization, the default is defined in APBFileHashDefaultChunkSizeForReadingData (4096)
 @param filePath CFStringRef that points to a valid filepath
 @param chunkSizeForReadingData size_t the size that we want to read a file into a hash. Default is 4096 
 @return stringref of the MD5 of the file. 
*/
FILEMD5HASH_EXTERN CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath, 
                                                         size_t chunkSizeForReadingData);


#endif
