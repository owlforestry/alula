require 'powerbar'

module Alula
  class Engine
    class ProgressBar < PowerBar
      attr_accessor :message, :done, :total
      
      def initialize(msg, total, opts = {})
        super(opts)
        
        @message = "%20s" % msg
        @done = 0
        @total = total
        
        self.settings.tty.finite.template.main = '${<msg>}: ${<percent>% } ${[<bar>] }${ ETA: <eta>}'
        self.settings.tty.finite.template.barchar = 'o'
        self.settings.tty.finite.template.padchar = ' '
        self.settings.tty.finite.template.close = "\e[?25h" if opts[:multi]
      end
      
      def file_transfer_mode
        self.settings.tty.finite.template.main = '${<msg>}: ${<percent>% } ${[<bar>] }${<rate>/s }${<done>}${ ETA: <eta>}'
      end
      
      def inc
        @done += 1
        self.show(:msg => @message, :done => @done, :total => @total)
      end
      
      def set(value)
        @done = value
        self.show(:msg => @message, :done => @done, :total => @total)
      end
      
      def vanish
        self.wipe
      end
      
      def finish
        self.close(true)
      end
      
      private
      # Monkey-patch to force percentage always being three characters long
      def h_percent
        sprintf "%3d", percent
      end
    end
  end
end
