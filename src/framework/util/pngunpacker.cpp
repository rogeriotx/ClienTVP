/* Copyright (C) Trubit Soft Sp. z o.o. - All Rights Reserved
 *
 * Unauthorized using, copying, modifying, merging, publishing,
 * distributing, sublicensing, and/or selling copies of the Software via any
 * medium is strictly prohibited
 * Proprietary and confidential
 * Written by Mariusz Mierzwa <mariusz.mierzwa@trubitsoft.com>, 14.06.2021
*/
#include "pngunpacker.h"

FileMetadata::FileMetadata(const FileStreamPtr& file)
{
	offset = file->getU32();
	fileSize = file->getU32();
	fileName = file->getString();
}

std::unordered_map<uint32_t, std::string> PngUnpacker::unpack(const FileStreamPtr& file)
{
	std::unordered_map<uint32_t, std::string> data;

	uint32_t entries = file->getU32();
	std::vector<FileMetadata> metadata;
	metadata.reserve(entries);
	for (uint32_t i = 0; i < entries; ++i) {
		metadata.emplace_back(file);
	}

	uint pos = file->tell();
	for (const auto& fileMetadata : metadata) {
		uint32_t imageID = std::stoi(fileMetadata.getFileName());
		auto it = data.emplace(imageID, std::string(fileMetadata.getFileSize(), '\0'));
		if (!it.second)
			continue; // duplicated
		file->seek(pos + fileMetadata.getOffset());
		file->read(it.first->second.data(), fileMetadata.getFileSize());
	}
	return data;
}

std::unordered_map<std::string, std::string> PngUnpacker::unpackRawNames(const FileStreamPtr& file)
{
	std::unordered_map<std::string, std::string> data;

	uint32_t entries = file->getU32();
	std::vector<FileMetadata> metadata;
	metadata.reserve(entries);
	for (uint32_t i = 0; i < entries; ++i) {
		metadata.emplace_back(file);
	}

	uint pos = file->tell();
	for (const auto& fileMetadata : metadata) {
		auto it = data.emplace(fileMetadata.getFileName(), std::string(fileMetadata.getFileSize(), '\0'));
		if (!it.second)
			continue; // duplicated
		file->seek(pos + fileMetadata.getOffset());
		file->read(it.first->second.data(), fileMetadata.getFileSize());
	}
	return data;
}

