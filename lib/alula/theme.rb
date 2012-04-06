module Alula
  class Theme
    def self.register(path)
      @@themepaths ||= []
      @@themepaths << path
    end
    
    def self.find_theme(themename)
      themepath = nil
      @@themepaths ||= []
      @@themepaths.each do |path|
        if File.directory?(File.join(path, themename))
          themepath = path
        end
      end

      themepath
    end
    
    def self.paths
      @@themepaths
    end
  end
end
