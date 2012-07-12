require 'alula/progressbar'

module Alula
  class Progress
    def initialize(options)
      @pbars = {}
      @interval = 1.0
      @options = options
    end
    
    def create(identifier, opts)
      if @pbars[identifier]
        @pbars[identifier].finish
        @pbars.delete(identifier)
      end
      
      @pbars[identifier] = ProgressBar.new(opts[:title], opts[:total] == 0 ? 0.1 : opts[:total])
    end
    
    def step(identifier)
      if @pbars[identifier]
        @pbars[identifier].step
      end
    end

    def set(identifier, value)
      if @pbars[identifier]
        @pbars[identifier].set(value)
      end
    end
    
    def set_file_transfer(identifier)
      if @pbars[identifier]
        @pbars[identifier].file_transfer_mode
      end
    end
    
    def finish(identifier)
      if @pbars[identifier]
        @pbars[identifier].finish
        _display
        @pbars.delete(identifier)
      end
    end
    
    def display
      _display(true)
      unless @options[:debug]
        @update_thread = Thread.new {
          loop {
            sleep(@interval)
            _display
          }
        }
      end
    end
    
    def hide
      if @update_thread
        Thread.kill(@update_thread)
      end
    end
    
    private
    def _display(first = false)
      output = @pbars.collect {|identifier, pbar| pbar.render }
      unless @options[:debug] or first
        print "\e[#{output.count}F"
      end
      puts output.join("\n")
    end
  end
end
