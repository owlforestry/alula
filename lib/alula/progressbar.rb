require 'powerbar'

module Alula
  class ProgressBar < PowerBar
    attr_accessor :showing
    
    def initialize(message, total, opts = {})
      super(opts)
      
      @message = "%20s" % message
      @done = 0
      @total = total
      
      @showing = true
      
      self.settings.tty.finite.template.main = '${<msg>}: ${<percent>% } ${[<bar>] }${ ETA: <eta>}'
      self.settings.tty.finite.template.barchar = 'o'
      self.settings.tty.finite.template.padchar = ' '
      self.settings.tty.finite.template.close = "\e[?25h" if opts[:multi]
    end
    
    def file_transfer_mode
      self.settings.tty.finite.template.main = '${<msg>}: ${<percent>% } ${[<bar>] }${<rate>/s }${<done>}${ ETA: <eta>}'
    end
    
    def render(opts = {})
      super({msg: @message, done: @done, total: @total}.merge(opts))
    end
    
    def step
      @done += 1
    end
    
    def set(value)
      @done = value
    end
    
    def vanish
      self.wipe
    end
    
    def finish(fill = true)
      # self.close(true)
      render(
        {
          :done => fill && !state.total.is_a?(Symbol) ? state.total : state.done,
          :tty => {
                    :finite => { :show_eta => false },
                    :infinite => { :show_eta => false },
                  },
          :notty => {
                    :finite => { :show_eta => false },
                    :infinite => { :show_eta => false },
                  },
        })
      # scope.output.call(scope.template.close) unless scope.template.close.nil?
      state.closed = true
    end
    
    private
    # Monkey-patch to force percentage always being three characters long
    def h_percent
      sprintf "%3d", percent
    end
  end
end
