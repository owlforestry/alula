#=require jquery
# Copyright Owl Forstry
# Alula JavaScript additions

jQuery.getDevicePixelRatio = ->
		if window.devicePixelRatio is undefined
			return 1
		else
			return window.devicePixelRatio
