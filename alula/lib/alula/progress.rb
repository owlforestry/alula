require 'alula/progressbar'

module Alula
  class Progress
    def initialize(options)
      @pbars = {}
      @interval = 1.0
      @options = options
      @display = false
      
      @@lock = Mutex.new
    end
    
    def create(identifier, opts)
      if @pbars[identifier]
        @pbars[identifier].finish
      end
      
      @@lock.synchronize do
        @pbars[identifier] = ProgressBar.new(opts[:title], opts[:total] == 0 ? 0.1 : opts[:total])
        if @options[:debug]
          @pbars[identifier].settings.force_mode = :notty
        end
      end
    end
    
    def step(identifier)
      if @pbars[identifier]
        @pbars[identifier].step
        _display
      end
    end

    def set(identifier, value)
      if @pbars[identifier]
        @pbars[identifier].set(value)
      end
    end
    
    def title(identifier, title)
      if @pbars[identifier]
        @pbars[identifier].message = title
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
        @@lock.synchronize do
          @pbars.delete(identifier)
        end
      end
    end
    
    def display
      @display = true
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
      @display = false
      if @update_thread
        Thread.kill(@update_thread)
      end
    end
    
    private
    def _display(first = false)
      return unless @display
      
      @@lock.synchronize do
        output = @pbars.collect {|identifier, pbar| pbar.render }
        unless @options[:debug] or first
          print "\e[#{output.count}F"
        end
        puts output.join("\n")
      end
    end
  end
end
