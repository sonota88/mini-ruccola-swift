require "rake/clean"

C_RESET = "\e[m"
C_RED = "\e[0;31m"

task :default => :build

CLEAN.include "bin/mrclc"

task :build => [
       "bin/mrclc"
     ]

file "bin/mrclc" => [
       "main.swift",
       "mrcl_lexer.swift",
       "mrcl_parser.swift",
       "mrcl_codegen.swift",
       "json_tester.swift",
       "lib/utils.swift",
       "lib/types.swift",
       "lib/json.swift",
     ] do |t|
  src_files = t.prerequisites.join(" ")

  sh %( swiftc -emit-executable -o #{t.name} #{src_files} 2>&1 ) do |ok, status|
    exit status.exitstatus
  end
end
