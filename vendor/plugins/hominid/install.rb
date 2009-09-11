require 'fileutils'
monkeyBrains = File.dirname(__FILE__) + '/../../../config/hominid.yml'
FileUtils.cp File.dirname(__FILE__) + '/hominid.yml.tpl', monkeyBrains unless File.exist?(monkeyBrains)
puts IO.read(File.join(File.dirname(__FILE__), 'README'))