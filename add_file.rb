require 'xcodeproj'

project_path = 'UniRide.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath(File.join('UniRide', 'ViewControllers', 'Profile'), true)

file_path = 'UniRide/ViewControllers/Profile/EditHomeLocationViewController.swift'
file_ref = group.new_reference(file_path)

target.source_build_phase.add_file_reference(file_ref)

project.save
