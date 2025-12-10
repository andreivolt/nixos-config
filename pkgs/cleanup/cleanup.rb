#!/usr/bin/env ruby

require 'fileutils'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on('-n', '--dry-run', 'Show what would be deleted') { options[:dry_run] = true }
end.parse!

DRY_RUN = options[:dry_run]

def expand_path(path)
  File.expand_path(path.gsub('~', ENV['HOME']))
end

def safe_delete(path, desc = nil)
  return unless File.exist?(path) || Dir.exist?(path)

  desc ||= File.basename(path)
  size = `du -sh "#{path}" 2>/dev/null`.split.first rescue '0B'

  if DRY_RUN
    puts "Would delete: #{desc} (#{size})"
  else
    FileUtils.rm_rf(path) rescue nil
  end
end

def scan_patterns(base_dir, patterns, desc)
  return unless Dir.exist?(expand_path(base_dir))

  patterns.each do |pattern|
    begin
      Dir.glob(File.join(expand_path(base_dir), '**', pattern)).each do |match|
        next unless Dir.exist?(match) && !%w[. ..].include?(File.basename(match))
        safe_delete(match, "#{desc}: #{File.basename(match)}")
      end
    rescue Errno::EPERM
      # Skip directories that require special permissions
      next
    end
  end
end

%w[
  ~/Library/Caches
  ~/Library/Saved\ Application\ State
  ~/Library/Logs/DiagnosticReports
].each { |path| safe_delete(expand_path(path)) }

patterns = %w[*caches* *Cache* *cache* Cached* *Code\ Cache* *log* *tmp* *trash*]
%w[~/Library ~/Library/Application\ Support ~/Library/Preferences].each do |dir|
  scan_patterns(dir, patterns, 'Cache patterns')
end

unless DRY_RUN
  print "Clean /Library/Caches? (requires sudo) [y/N]: "
  system('sudo rm -rf /Library/Caches/* 2>/dev/null') if gets.chomp.downcase.start_with?('y')
end

{
  cargo: %w[~/.cargo/git ~/.cargo/registry],
  sbt: %w[~/.sbt/0.13 ~/.sbt/1.0 ~/.sbt/boot],
  maven: %w[~/.m2/repository ~/.m2/wrapper],
  ivy2: %w[~/.ivy2/cache],
  gradle: %w[~/.gradle/build-scan-data ~/.gradle/caches ~/.gradle/daemon ~/.gradle/jdks ~/.gradle/kotlin-profile ~/.gradle/native ~/.gradle/notifications ~/.gradle/workers ~/.gradle/wrapper],
  npm: %w[~/.npm/_cacache ~/.npm/_logs],
  buildpack: %w[~/.pack/download-cache],
  xcode: ['~/Library/Developer/Xcode/DerivedData', '~/Library/Developer/Xcode/Archives', '~/Library/Developer/Xcode/iOS Device Logs', '~/Library/Developer/Xcode/iPadOS Device Logs', '~/Library/Developer/Xcode/macOS Device Logs']
}.each do |tool, paths|
  paths.each { |path| safe_delete(expand_path(path)) }
end

workspace_path = Dir.pwd

{
  'src-tauri/Cargo.toml' => ['node_modules', '.parcel-cache', 'dist', 'src-tauri/target', 'target'],
  'Cargo.toml' => ['target'],
  'package.json' => ['node_modules', '.parcel-cache', 'dist', 'build'],
  'build.gradle' => ['build'],
  'build.gradle.kts' => ['build'],
  'settings.gradle.kts' => ['build'],
  'build.sbt' => ['target'],
  'pom.xml' => ['target'],
  'build.sc' => ['out']
}.each do |marker, artifacts|
  Dir.glob(File.join(workspace_path, '**', marker)).each do |marker_file|
    project_root = marker.include?('src-tauri/') ? File.dirname(File.dirname(marker_file)) : File.dirname(marker_file)

    artifacts.each do |artifact|
      if artifact.include?('*/')
        Dir.glob(File.join(project_root, artifact)).each { |match| safe_delete(match) }
      else
        safe_delete(File.join(project_root, artifact))
      end
    end
  end
end


unless DRY_RUN
  system('brew cleanup --prune all')
  system('gem cleanup')
end
