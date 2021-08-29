#!/usr/local/bin/python3

import os

# get current script dir path
script_dir = os.path.dirname(os.path.realpath(__file__))

# remove last patch component and append Foundation
working_dir = script_dir.rsplit('/', 1)[0]
framework_dir = working_dir + '/Foundation'

print('[*] scaning at ' + working_dir)

# get all files include subfolers with LICENSE in file name
license_files = []
for root, dirs, files in os.walk(framework_dir):
    for file in files:
        if 'LICENSE' in file:
            license_files.append(os.path.join(root, file))

# for each license file, get it's parent dir as key, create dic
framework_license_dic = {}
for f in license_files:
    dirname = os.path.dirname(f)
    parent_dir = dirname.rsplit('/', 1)[1]
    framework_license_dic[parent_dir] = f

# remove dir at build if exists
if os.path.exists(working_dir + '/build/License'):
    os.system('rm -rf ' + working_dir + '/build/License')

# create dir at '/build/License'
os.system('mkdir -p ' + working_dir + '/build/License')

# create a file called ScannedLicense at '/build/License' 
with open(working_dir + '/build/License/ScannedLicense', 'w') as f:
    # read all license files sorted by key and write to ScannedLicense
    for key, value in sorted(framework_license_dic.items()):
        print('[*] writing ' + key + ': ' + value)
        with open(value, 'r') as l:
            f.write(key + '\n\n')
            f.write(l.read())
            f.write('\n\n')

print('[*] done')
