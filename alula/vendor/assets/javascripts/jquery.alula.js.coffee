#=require jquery
#
# Copyright Owl Forstry
# Alula JavaScript additions

# Make sure we have devicePixelRatio always available
jQuery.getDevicePixelRatio = ->
		if window.devicePixelRatio is undefined
			return 1
		else
			return window.devicePixelRatio

# Hide mobile Safari address bar
jQuery ->
	delay = (ms, func) -> setTimeout func, ms
	delay 0, -> window.scrollTo(0, 1)