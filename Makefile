VERSION = 0.9
PRODUCT = llfw

BINARY = llfw
SWIFT_OUT = .build/apple/Products/Release/${PRODUCT}

CODESIGN_IDENTITY = "Developer ID Application: Your Name (XXXXXXXXXX)"
BUNDLE_ID = edu.umich.its.${PRODUCT}
NOTARYTOOL_PROFILE = umich-edu

Binaries/${BINARY}:
	-swift build -c release --product ${PRODUCT}  --arch arm64 --arch x86_64
	xcrun codesign -s ${CODESIGN_IDENTITY} \
               --options=runtime \
               --timestamp \
               ${SWIFT_OUT}
	rm -rf out || true
	mkdir -p Binaries
	cp ${SWIFT_OUT} Binaries/${BINARY}

.PHONY: build
build: Binaries/${BINARY}

.PHONY: dmg
dmg: ${BINARY}-${VERSION}.dmg

${BINARY}-${VERSION}.dmg:
	hdiutil create -volname "${PRODUCT}" -srcfolder "Binaries" -ov -format UDZO "${BINARY}-${VERSION}.dmg"
	xcrun notarytool \
		submit \
		--wait \
		--keychain-profile ${NOTARYTOOL_PROFILE} \
		"${BINARY}-${VERSION}.dmg"
	xcrun stapler staple "${BINARY}-${VERSION}.dmg"

.PHONY: clean
clean:
	rm -rf Packages Binaries .build ${BINARY}.dmg
