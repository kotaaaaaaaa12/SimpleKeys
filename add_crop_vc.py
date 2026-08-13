from pbxproj import XcodeProject

project = XcodeProject.load('SimpleKeys.xcodeproj/project.pbxproj')
project.add_file('SimpleKeys/ImageCropViewController.swift', target_name='SimpleKeys', force=False)
project.save()
