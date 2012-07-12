#=require jquery.alula
#=require jquery.lazyload

jQuery ->
	# Hi-res support
	if jQuery.getDevicePixelRatio() <= 1
		jQuery("img[data-original]").lazyload
			data_attribute: "original"
	else
		# Replace 2x images
		jQuery("img[data-hires]").lazyload
			data_attribute: "hires"
		# Replace remaining
		jQuery("img[data-original]:not('[data-hires]')").lazyload
			data_attribute: "original"