# SWCompression

[![Swift 5.2+](https://img.shields.io/badge/Swift-5.2+-blue.svg)](https://developer.apple.com/swift/)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/tsolomko/SWCompression/master/LICENSE)
[![Build Status](https://dev.azure.com/tsolomko/SWCompression/_apis/build/status/tsolomko.SWCompression?branchName=develop)](https://dev.azure.com/tsolomko/SWCompression/_build/latest?definitionId=3&branchName=develop)

A framework with (de)compression algorithms and functions for working with various archives and containers.

## What is this?

SWCompression is a framework with a collection of functions for:

1. Decompression (and sometimes compression) using different algorithms.
2. Reading (and sometimes writing) archives of different formats.
3. Reading (and sometimes writing) containers such as ZIP, TAR and 7-Zip.

It also works on Apple platforms, Linux, __and Windows__.

All features are listed in the tables below. "TBD" means that feature is planned but not implemented (yet).

|               | Deflate | BZip2 | LZMA/LZMA2 | LZ4 |
| ------------- | ------- | ----- | ---------- | --- |
| Decompression | ✅      | ✅     | ✅         | ✅  |
| Compression   | ✅      | ✅     | TBD        | ✅  |

|       | Zlib | GZip | XZ  | ZIP | TAR | 7-Zip |
| ----- | ---- | ---- | --- | --- | --- | ----- |
| Read  | ✅   | ✅    | ✅  | ✅  | ✅   | ✅    |
| Write | ✅   | ✅    | TBD | TBD | ✅   | TBD   |

Also, SWCompression is _written with Swift only._

## Installation

SWCompression can be integrated into your project using Swift Package Manager, CocoaPods, or Carthage.

### Swift Package Manager

To install using SPM, add SWCompression to you package dependencies and specify it as a dependency for your target, e.g.:

```swift
import PackageDescription

let package = Package(
    name: "PackageName",
    dependencies: [
        .package(name: "SWCompression", url: "https://github.com/tsolomko/SWCompression.git",
                 from: "4.8.0")
    ],
    targets: [
        .target(
            name: "TargetName",
            dependencies: ["SWCompression"]
        )
    ]
)
```

More details you can find in [Swift Package Manager's Documentation](https://github.com/apple/swift-package-manager/tree/main/Documentation).

### CocoaPods

Add `pod 'SWCompression', '~> 4.8'` and `use_frameworks!` lines to your Podfile.

To complete installation, run `pod install`.

If you need only some parts of framework, you can install only them using sub-podspecs. Available subspecs:

- SWCompression/BZip2
- SWCompression/Deflate
- SWCompression/Gzip
- SWCompression/LZMA
- SWCompression/LZMA2
- SWCompression/LZ4
- SWCompression/SevenZip
- SWCompression/TAR
- SWCompression/XZ
- SWCompression/Zlib
- SWCompression/ZIP

#### "Optional Dependencies"

For both ZIP and 7-Zip there is the most commonly used compression method: Deflate and LZMA/LZMA2 correspondingly. Thus,
SWCompression/ZIP subspec has SWCompression/Deflate subspec as a dependency and SWCompression/LZMA subspec is a
dependency for SWCompression/SevenZip.

But both of these formats also support other compression methods, and some of them are implemented in SWCompression.
For CocoaPods configurations there are some sort of 'optional dependencies' for such compression methods.

"Optional dependency" in this context means that SWCompression/ZIP or SWCompression/7-Zip will support a compression
method only if a corresponding subspec is expicitly specified in your Podfile and installed.

List of "optional dependecies":

- For SWCompression/ZIP:
    - SWCompression/BZip2
    - SWCompression/LZMA
- For SWCompression/SevenZip:
    - SWCompression/BZip2
    - SWCompression/Deflate
    - SWCompression/LZ4

__Note:__ If you use Swift Package Manager or Carthage you always have everything (ZIP and 7-Zip are built with Deflate,
BZip2, LZMA/LZMA2 and LZ4 support).

### Carthage

Add to your Cartfile `github "tsolomko/SWCompression" ~> 4.8`.

Then:

1. If you use Xcode 12 or later you should run `carthage update --use-xcframeworks`. After that drag and drop both
`SWCompression.xcframework` and `BitByteData.xcframework` files from from the `Carthage/Build/` directory into the
"Frameworks, Libraries, and Embedded Content" section of your target's "General" tab in Xcode.

2. If you use Xcode 11 or earlier you should run `carthage update`. After that drag and drop both
`SWCompression.framework` and `BitByteData.framework` files from from the `Carthage/Build/<platform>/` directory into
the "Embedded Binaries" section of your target's "General" tab in Xcode.

For Xcode 12 or later you can currently also use the
[xconfig workaround](https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md).

Please also note that support for non-xcframework method of installing SWCompression is likely to be dropped in the
future major update.

## Usage

### Basic Example

For example, if you want to decompress "deflated" data just use:

```swift
// let data = <Your compressed data>
let decompressedData = try? Deflate.decompress(data: data)
```

However, it is unlikely that you will encounter deflated data outside of any archive. So, in the case of GZip archive
you should use:

```swift
let decompressedData = try? GzipArchive.unarchive(archive: data)
```

### Handling Errors

Most SWCompression functions can throw errors and you are responsible for handling them. If you look at the list of
available error types and their cases, you may be frightened by their number. However, most of the cases (such as
`XZError.wrongMagic`) exist for diagnostic purposes.

Thus, you only need to handle the most common type of error for your archive/algorithm. For example:

```swift
do {
    // let data = <Your compressed data>
    let decompressedData = try XZArchive.unarchive(archive: data)
} catch let error as XZError {
    // <handle XZ related error here>
} catch let error {
    // <handle all other errors here>
}
```

### Documentation

Every function or type of SWCompression's public API is documented. This documentation can be found at its own
[website](http://tsolomko.github.io/SWCompression) or via a slightly shorter link:
[swcompression.tsolomko.me](http://swcompression.tsolomko.me)

### Sophisticated example

There is a small command-line program, "swcomp", which is included in this repository in "Sources/swcomp". It can be
built using Swift Package Manager.

__IMPORTANT:__ The "swcomp" command-line tool is NOT intended for general use.

## Contributing

Whether you find a bug, have a suggestion, idea, feedback or something else, please
[create an issue](https://github.com/tsolomko/SWCompression/issues) on GitHub. If you have any questions, you can ask
them on the [Discussions](https://github.com/tsolomko/SWCompression/discussions) page.

In the case of a bug, it will be especially helpful if you attach a file (archive, etc.) that caused the bug to occur.

If you'd like to contribute, please [create a pull request](https://github.com/tsolomko/SWCompression/pulls) on GitHub.

__Note:__ If you are considering working on SWCompression, please note that Xcode project (SWCompression.xcodeproj)
was created manually and you shouldn't use `swift package generate-xcodeproj` command.

### Executing tests locally

If you want to run tests on your computer, you need to do a couple of additional steps after cloning the repository:

```bash
./utils.py download-bbd-macos
git submodule update --init --recursive
cd "Tests/Test Files"
cp gitattributes-copy .gitattributes
git lfs pull
git lfs checkout
```

The first command will download the BitByteData dependency, which requires having Carthage installed. When using Xcode
12 or later, you should also pass the `--xcf` option, or use the
[xconfig workaround](https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md). Please note
that when building SWCompression's Xcode project you may see ld warnings about a directory not being found. These are
expected and harmless. Finally, you should keep in mind that support for non-xcframework method of installing
dependencies is likely to be dropped in the future major update.

The remaining commands will download the files used in tests. These files are stored in a
[separate repository](https://github.com/tsolomko/SWCompression-Test-Files), using Git LFS. There are two reasons for
this complicated setup. Firstly, some of these files can be quite big, and it would be unfortunate if the users of
SWCompression had to download them during the installation. Secondly, Swift Package Manager and contemporary versions of
Xcode don't always work well with git-lfs-enabled repositories. To prevent any potential problems test files were moved
into another repository.

Please note, that if you want to add a new _type_ of test files, in addition to running `git lfs track`, you have to
also copy into the "Tests/Test Files/gitattributes-copy" file a line this command adds to the "Tests/Test Files/.gitattributes"
file. __Do not commit the ".gitattributes" file to the git history. It is git-ignored for a reason!__

Please also be mindful of Git LFS bandwidth quota on GitHub: try to limit downloading lfs'd files using `git lfs pull`.
In CI we use some caching techniques to help with the quota, so if you're going to add new tests that require several
new test files you should try to submit them all together to reduce the amount of times CI needs to recreate the cache
(recreating the cache requires to do `git lfs pull` for all test files).

## Performance

Using whole module optimizations is recommended for the best performance. They are enabled by default in the Release build
configuration.

[Tests Results](Tests/Results.md) document contains results of benchmarking of various functions.

## Why?

First of all, existing solutions for working with compression, archives and containers have certain disadvantages. They
might not support a particular compression algorithm or archive format and they all have different APIs, which sometimes
can be slightly confusing for users, especially when you mix different libraries in one project. This project attempts to
provide missing (and sometimes existing) functionality through the unified API which is easy to use and remember.

Secondly, in some cases it may be important to have a compression framework written entirely in Swift, without relying
on either system libraries or solutions implemented in other languages. Additionaly, since SWCompression is written
completely in Swift without Objective-C, it can also be used on Linux, __and Windows__.

## Future plans

- Performance...
- Better Deflate compression.
- Something else...

## License

[MIT licensed](LICENSE)

## References

- [pyflate](http://www.paul.sladen.org/projects/pyflate/)
- [Deflate specification](https://www.ietf.org/rfc/rfc1951.txt)
- [GZip specification](https://www.ietf.org/rfc/rfc1952.txt)
- [Zlib specification](https://www.ietf.org/rfc/rfc1950.txt)
- [LZMA SDK and specification](http://www.7-zip.org/sdk.html)
- [XZ specification](http://tukaani.org/xz/xz-file-format-1.0.4.txt)
- [Wikipedia article about LZMA](https://en.wikipedia.org/wiki/Lempel–Ziv–Markov_chain_algorithm)
- [.ZIP Application Note](http://www.pkware.com/appnote)
- [ISO/IEC 21320-1](http://www.iso.org/iso/catalogue_detail.htm?csnumber=60101)
- [List of defined ZIP extra fields](https://opensource.apple.com/source/zip/zip-6/unzip/unzip/proginfo/extra.fld)
- [Wikipedia article about TAR](https://en.wikipedia.org/wiki/Tar_(computing))
- [Pax specification](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/pax.html)
- [Basic TAR specification](https://www.gnu.org/software/tar/manual/html_node/Standard.html)
- [star man pages](https://www.systutorials.com/docs/linux/man/5-star/)
- [Apache Commons Compress](https://commons.apache.org/proper/commons-compress/)
- [A walk through the SA-IS Suffix Array Construction Algorithm](http://zork.net/~st/jottings/sais.html)
- [Wikipedia article about BZip2](https://en.wikipedia.org/wiki/Bzip2)
- [LZ4 Frame Format Description](https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md)
- [LZ4 Block Format Description](https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md)
- [xxHash specification](https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md)
