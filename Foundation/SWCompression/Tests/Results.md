# Test Results

In this document you can find the results of benchmarking which was performed on Macbook Air, Retina, 13-inch, Early
2020 with 1,1 GHz Quad-Core Intel Core i5 CPU. The main purpose of these results is to track progress from version to
version.

## Changelog

__October 2021.__ Added uncertainties for the results where they were missing; added LZ4 compression and decompression
sections; compression results now also list compression ratio in brackets.

__September 2021.__ The results are now listed in terms of speed (e.g. MB/s); the benchmarks for Deflate, BZip2
compression and TAR container creation have been added; all previous results have been removed since newer hardware is
now used; added results for the `-Ounchecked` compiler option; the macOS version is now listed for results.

__April 2018.__ The first (zeroth, actually) iteration is now excluded from averages calculation since this iteration
has abnormally longer execution time than any of the following iterations. This exclusion led not only to (artificially)
improved results, but also to the increased quality of the results by reducing calculated uncertainty. In addition, the
averages are now computed over 10 iterations instead of 6.

__January 2018.__ SWCompression internal functionality related to reading/writing bits and bytes is published as a
separate framework, [BitByteData](https://github.com/tsolomko/BitByteData). The overall performance heavily depends on
the speed of reading and writing, and thus BitByteData's version, which is specified in a separate column in the tables
below, becomes relevant to benchmarking, since newer versions can contain performance improvements.

## Tests description

There are three different datasets for testing. When choosing them the intention was to have something
that represents real life situations. For obvious reasons these test files aren't provided anywhere
in the repository.

- Test 1: Git 2.15.0 Source Code.
- Test 2: Visual Studio Code 1.18.1 App for macOS.
- Test 3: Documentation directory from Linux kernel 4.14.2 Source Code.

All tests were run using swcomp's "benchmark" command. SWCompression (and swcomp) were compiled
using "Release" configuration.

__Note:__ External commands used to create compressed files were run using their default sets of options.

__Note:__ All results are averages over 10 iterations.

## BZip2 Decompress

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|2.366 ± 0.092 MB/s|2.569 ± 0.113 MB/s|2.106 ± 0.088 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|2.552 ± 0.080 MB/s|2.894 ± 0.052 MB/s|2.391 ± 0.062 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|2.764 ± 0.037 MB/s|2.973 ± 0.088 MB/s|2.410 ± 0.088 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|3.279 ± 0.429 MB/s|4.361 ± 0.306 MB/s|3.169 ± 0.180 MB/s|

## XZ Unarchive (LZMA/LZMA2 Decompress)

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|5.006 ± 0.304 MB/s|5.359 ± 0.130 MB/s|5.095 ± 0.220 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|5.210 ± 0.198 MB/s|5.436 ± 0.124 MB/s|5.224 ± 0.176 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|5.246 ± 0.279 MB/s|5.543 ± 0.143 MB/s|5.322 ± 0.260 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|6.015 ± 0.319 MB/s|6.374 ± 0.143 MB/s|5.841 ± 0.212 MB/s|

## GZip Unarchive (Deflate Decompress)

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|4.982 ± 0.128 MB/s|4.994 ± 0.122 MB/s|4.899 ± 0.326 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|5.912 ± 0.232 MB/s|5.997 ± 0.100 MB/s|6.004 ± 0.259 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|5.946 ± 0.432 MB/s|6.034 ± 0.175 MB/s|6.071 ± 0.250 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|8.562 ± 0.388 MB/s|9.908 ± 0.204 MB/s|8.286 ± 0.250 MB/s|

## LZ4 Decompress

For LZ4 decompression we report results both for independent and dependent blocks, since
this setting may significantly affect performance.

### Independent blocks

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|17.079 ± 0.943 MB/s|22.253 ± 0.872 MB/s|16.650 ± 0.406 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|17.496 ± 0.817 MB/s|22.480 ± 0.524 MB/s|16.751 ± 0.902 MB/s|

### Dependent blocks

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|17.235 ± 0.720 MB/s|21.056 ± 0.884 MB/s|15.950 ± 0.773 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|17.065 ± 1.109 MB/s|22.508 ± 0.568 MB/s|16.735 ± 0.605 MB/s|

## BZip2 Compress

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|3.450 ± 0.088 MB/s (3.493)|2.793 ± 0.034 MB/s (2.635)|4.182 ± 0.084 MB/s (3.875)|
|4.7.0|2.0.1|12.0.1|5.5.1|3.466 ± 0.048 MB/s (3.493)|2.767 ± 0.013 MB/s (2.635)|4.077 ± 0.069 MB/s (3.875)|
|4.6.0|2.0.1|11.5.2|5.4.2|3.540 ± 0.055 MB/s|2.862 ± 0.013 MB/s|4.253 ± 0.077 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|3.816 ± 0.078 MB/s|3.060 ± 0.028 MB/s|4.647 ± 0.085 MB/s|

## Deflate Compress

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|15.354 ± 0.330 MB/s (2.540)|11.420 ± 0.138 MB/s (2.266)|17.306 ± 0.614 MB/s (2.831)|
|4.7.0|2.0.1|12.0.1|5.5.1|15.703 ± 0.538 MB/s (2.540)|11.592 ± 0.219 MB/s (2.266)|17.547 ± 0.731 MB/s (2.831)|
|4.6.0|2.0.1|11.5.2|5.4.2|12.177 ± 0.259 MB/s|8.809 ± 0.088 MB/s|13.594 ± 0.355 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|12.914 ± 0.355 MB/s|9.361 ± 0.078 MB/s|15.020 ± 0.277 MB/s|

## LZ4 Compress

For LZ4 compression we report results both for independent and dependent blocks, since
this setting may significantly affect performance.

### Independent blocks

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|32.921 ± 0.923 MB/s (2.620)|22.635 ± 0.368 MB/s (2.278)|35.672 ± 2.053 MB/s (2.981)|
|4.7.0|2.0.1|12.0.1|5.5.1|32.692 ± 1.990 MB/s (2.620)|22.702 ± 0.423 MB/s (2.278)|35.405 ± 2.119 MB/s (2.981)|

### Dependent blocks

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|31.991 ± 1.434 MB/s (2.622)|21.973 ± 0.433 MB/s (2.280)|35.187 ± 1.315 MB/s (2.983)|
|4.7.0|2.0.1|12.0.1|5.5.1|32.234 ± 1.673 MB/s (2.622)|21.960 ± 0.531 MB/s (2.280)|34.729 ± 1.996 MB/s (2.983)|

## 7-Zip Info Function

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|89.018 ± 10.089 MB/s|125.155 ± 10.977 MB/s|42.353 ± 1.286 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|86.216 ± 11.562 MB/s|135.372 ± 12.394 MB/s|43.499 ± 1.771 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|77.072 ± 6.625 MB/s|111.246 ± 4.855 MB/s|38.721 ± 2.681 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|82.367 ± 7.381 MB/s|116.923 ± 3.812 MB/s|38.519 ± 2.988 MB/s|

## TAR Info Function

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|953.555 ± 113.704 MB/s|1.016 ± 0.086 GB/s|223.068 ± 15.446 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|963.424 ± 107.448 MB/s|1.035 ± 0.078 GB/s|224.862 ± 8.902 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|967.792 ± 58.436 MB/s|1.006 ± 0.069 GB/s|217.082 ± 19.783 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|1.073 ± 0.115 GB/s|1.053 ± 0.071 GB/s|246.854 ± 6.763 MB/s|

## TAR Reader

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|467.082 ± 27.789 MB/s|526.799 ± 47.046 MB/s|139.247 ± 8.510 MB/s|

## ZIP Info Function

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|615.038 ± 90.624 MB/s|1.888 ± 0.224 GB/s|377.717 ± 48.155 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|587.776 ± 159.763 MB/s|2.150 ± 0.148 GB/s|389.327 ± 104.806 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|597.002 ± 75.017 MB/s|1.941 ± 0.135 GB/s|389.626 ± 22.006 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|685.266 ± 53.895 MB/s|2.147 ± 0.097 GB/s|420.461 ± 15.156 MB/s|

## TAR Create Function

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|145.817 ± 10.452 MB/s|486.193 ± 24.090 MB/s|237.893 ± 17.378 MB/s|
|4.7.0|2.0.1|12.0.1|5.5.1|143.668 ± 9.892 MB/s|476.701 ± 26.328 MB/s|233.040 ± 14.406 MB/s|
|4.6.0|2.0.1|11.5.2|5.4.2|139.649 ± 8.310 MB/s|446.101 ± 21.476 MB/s|215.556 ± 17.5 MB/s|
|4.6.0-unchecked|2.0.1|11.5.2|5.4.2|142.681 ± 5.664 MB/s|459.403 ± 17.862 MB/s|220.238 ± 3.476 MB/s|

## TAR Writer

|SWCompression<br>version|BitByteData<br>version|macOS<br>version|Swift<br>version|Test 1|Test 2|Test 3|
|:---:|:---:|:---:|:---:|---|---|---|
|4.8.0|2.0.1|12.1|5.5.2|19.881 ± 0.766 MB/s|83.901 ± 4.690 MB/s|28.614 ± 2.938 MB/s|
