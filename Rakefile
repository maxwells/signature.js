require 'closure-compiler'

task :compile do
  src_files = File.join("**", "src", "**", "*.coffee")
  Dir.glob(src_files).each do |f|
    compiled_f = "lib/#{File.basename(f, '.coffee')}.js"
    puts "Compiling #{f} to #{compiled_f}"
    `coffee --output lib --compile #{f}`
    minified_f = "lib/#{File.basename(f, '.coffee')}.min.js"
    puts "Compressing #{compiled_f} to #{minified_f}"
    File.open(minified_f, 'wb') do|f|
      f.write Closure::Compiler.new.compile(File.open(compiled_f, 'r'))
    end
    
  end
end

task :spec do
  src_files = File.join("**", "spec", "**", "*.coffee")
  Dir.glob(src_files).each do |f|
    puts "Compiling #{f} to spec/#{File.basename(f, '.coffee')}.js"
    `coffee --compile #{f}`
  end
end

task :default => [:compile, :spec]