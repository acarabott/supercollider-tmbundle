#!/usr/bin/ruby
#SCvim pipe
#this is a script to pass things from scvim to sclang
#
#Copyright 2007 Alex Norman
# 
# modified 2010 stephen lumenta to work with the supercollider-txtmate-bundle
# 
# http://github.com/sbl/supercollider-tmbundle
#
#This file is part of SCVIM.
#
#SCVIM is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#SCVIM is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with SCVIM.  If not, see <http://www.gnu.org/licenses/>.
# 


require 'fileutils'
require 'singleton'

module SC
  
  class Pipe        
    include Singleton
    
    @@pipe_loc = "/tmp/sclang-pipe"
    @@rundir = "/Applications/SuperCollider"
    @@pid_loc = "/tmp/sclangpipe_app-pid" 
    @@app = File.join(@@rundir, 'sclang')            
        
    
    class << self
      def serve
        prepare_pipe
        run_pipe
        clean_up      
      end
      
      def pipe_loc
        @@pipe_loc
      end
      
      def pid_loc
        @@pid_loc
      end
    end
  
    private
    
    class << self   
      def prepare_pipe
        File.open(@@pid_loc, "w"){ |f|
          f.puts Process.pid
        }

        #remove the pipe if it exists
        if File.exists?(@@pipe_loc)
          FileUtils.rm(@@pipe_loc)
        end
        #make a new pipe
        system("mkfifo", @@pipe_loc)
      end
     
      def run_pipe
        pipeproc = Proc.new {
          trap("INT") do
            Process.exit
          end
          IO.popen("#{@@app} -d #{@@rundir.chomp}", "w") do |sclang|
            loop {
              x = `cat #{@@pipe_loc}`
              sclang.print x if x
            }
          end
        }
      
        $p = Process.fork { pipeproc.call }
      
      end

      def clean_up
        #if we get a hup then we kill the pipe process and
        #restart it
        trap("HUP") do
          Process.kill("INT", $p)
          $p = Process.fork { pipeproc.call }
        end

        #clean up after us
        trap("INT") do
          FileUtils.rm(@@pipe_loc)
          FileUtils.rm(@@pid_loc)
          exit
        end
        #we sleep until a signal comes
        sleep(1) until false
      end
    end
  end #END CLASS
end