# NDISwiftPackage
Sample project with local swift package linked NDI SDK.

## Preparation

1. Install NDA SDK on mac

[Software Developer Kit](https://ndi.tv/sdk/#download)

2. Make package configuration file on `/usr/local/lib/pkgconfig/`

```
NDI_SDK_ROOT=/Library/NDI\ SDK\ for\ Apple

Name: NDI SDK for iOS
Description: The NDI SDK for iOS
Version: 5.1.1
Cflags: -I${NDI_SDK_ROOT}/include
Libs: -L${NDI_SDK_ROOT}/lib/iOS -lndi_ios
```

## References
- [stackoverflow - Link to fat Static Library inside Swift Package](https://stackoverflow.com/questions/70557329/link-to-fat-static-library-inside-swift-package)
