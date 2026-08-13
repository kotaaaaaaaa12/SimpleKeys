from pbxproj import XcodeProject

project = XcodeProject.load('SimpleKeys.xcodeproj/project.pbxproj')
project.add_file('SimpleKeys/CustomFontManager.swift', target_name='SimpleKeys', force=False)
project.add_file('SimpleKeys/CustomFontManager.swift', target_name='KeyboardExtension', force=False)
project.save()
