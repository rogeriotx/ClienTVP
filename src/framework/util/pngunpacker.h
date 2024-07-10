/* Copyright (C) Trubit Soft Sp. z o.o. - All Rights Reserved
 *
 * Unauthorized using, copying, modifying, merging, publishing,
 * distributing, sublicensing, and/or selling copies of the Software via any
 * medium is strictly prohibited
 * Proprietary and confidential
 * Written by Mariusz Mierzwa <mariusz.mierzwa@trubitsoft.com>, 14.06.2021
 */
 
#ifndef __PNG_UNPACKER_H
#define __PNG_UNPACKER_H

#include <framework/core/declarations.h>
#include <framework/core/filestream.h>
#include <framework/graphics/declarations.h>

 /* File unpacking related */
class FileMetadata
{
public:
	FileMetadata(const FileStreamPtr& file);

	const std::string& getFileName() const { return fileName; }
	uint32_t getOffset() const { return offset; }
	uint32_t getFileSize() const { return fileSize; }
private:
	std::string fileName;
	uint32_t offset = 0;
	uint32_t fileSize = 0;
};

class PngUnpacker
{
public:
	static std::unordered_map<uint32_t, std::string> unpack(const FileStreamPtr& file);
	static std::unordered_map<std::string, std::string> unpackRawNames(const FileStreamPtr& file);
};

#endif
