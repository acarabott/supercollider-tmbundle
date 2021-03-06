#!/usr/bin/env ruby -wKU

# copyright 2010 sbl
# part of the supercollider textmate bundle 

require 'fileutils'
require 'sc/pipe'

module SC

  class Dispatcher
    
    def initialize
      unless File.exists?(SC::Pipe.pipe_loc && SC::Pipe.pid_loc)
        raise "Please run a sclang session first."
      end
      @pipe = SC::Pipe.pipe_loc
    end
    
    def interpret(sc_code)
      open(@pipe, "w") { |io| io << "#{sc_code}\x0c" }
    end
        
  end
end