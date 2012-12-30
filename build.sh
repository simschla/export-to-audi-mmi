#!/bin/bash

# local vars
SRC_FILE=Export\ to\ Audi\ MMI.applescript
TARGET_FILE=Export\ to\ Audi\ MMI.app

# dest vars
DEST_LOCATION=~/Library/iTunes/Scripts
DEST_FILE=${DEST_LOCATION}/${TARGET_FILE}

# remove locally built file if existing
if [[ -e "${TARGET_FILE}" ]]; then
	rm -r "${TARGET_FILE}"
fi

# build the new version
/usr/bin/osacompile -o "${TARGET_FILE}" "${SRC_FILE}"

# make sure to remove a potentially existing version
if [[ -e "${DEST_FILE}" ]]; then
	rm -r "${DEST_FILE}"
fi

# make sure target path exists
if [[ ! -e "${DEST_LOCATION}" ]]; then
	mkdir -p "${DEST_LOCATION}"
fi

# copy the new version to destination
cp -r "${TARGET_FILE}" "${DEST_LOCATION}"
