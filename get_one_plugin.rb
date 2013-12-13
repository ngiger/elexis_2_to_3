#!/usr/bin/ruby
require 'pp'
require 'fileutils'

exit 2 unless ARGV.size == 1
origin = ARGV[0]
unless File.directory?(origin)
  puts "You must specify a directory to copy"
  exit 2
end
plugin = File.basename(origin)
puts "Getting #{plugin} from #{origin}"
FileUtils.rm_rf("#{plugin}*", :verbose => true)
FileUtils.cp_r(origin, Dir.pwd, :preserve => true)
toAdd = [ plugin ]
test_projects = Dir.glob("#{origin}*test*/.project")
pp test_projects
if test_projects.size == 1
  test_projects.each{|project|
    dir = File.dirname(project)
                    pp dir 
    test_name = "#{plugin}.tests"
                    pp test_name
                    FileUtils.makedirs test_name
    FileUtils.cp_r("#{dir}", test_name, :preserve => true, :verbose => true)
    # FileUtils.cp_r(dir, Dir.pwd, :preserve => true, :verbose => true)
#    FileUtils.mv(File.basename(dir), test_name, :verbose => true)
    toAdd << test_name
  }
end
pp toAdd
cmd ="git add #{toAdd.join(' ')}"
puts cmd
exit 2 unless system(cmd)
files2rm = (Dir.glob("#{plugin}/**/*.jar")+Dir.glob("#{plugin}/**/*.orig")+Dir.glob("#{plugin}/**/*.rej")+Dir.glob("#{plugin}/**/*~"))
FileUtils.rm(files2rm, :verbose => true)
toAdd.each{ |dir|
  cmd ="git commit #{dir} -m 'Added #{dir} as found in elexis 2.1.7'"
  puts cmd
  exit 2 unless system(cmd)
  cmd ="./elexis_2_to_3.rb #{plugin}"
  puts cmd
  exit 2 unless system(cmd)
}

cmd ="git add #{toAdd.join(' ')} #{plugin}.feature"
puts cmd
exit 2 unless system(cmd)
cmd ="git commit -m 'Called elexis_2_to_3.rb for #{plugin}' --all"
puts cmd
exit 2 unless system(cmd)
puts "Migrated successfully #{toAdd.join(' ')}"
