#=require jquery.alula
#=require jquery.lazyload

jQuery ->
	# Retina support
	if $.getDevicePixelRatio() <= 1
		jQuery("img[data-original]").lazyload
			data_attribute: "original"
	else
		# Replace 2x images
		jQuery("img[data-retina]").lazyload
			data_attribute: "retina"
		# Replace remaining
		jQuery("img[data-original]:not('[data-retina]')").lazyload
			data_attribute: "original"