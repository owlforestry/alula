#=require jquery

MinimalTheme =
	reorder: ->
		screenWidth = jQuery(window).width()
		
		if screenWidth <= 720
			jQuery('.below_fold').prependTo(jQuery("footer"))
		else
			jQuery('.below_fold').appendTo(jQuery("header"))
		
jQuery ->
	jQuery(window).resize ->
		MinimalTheme.reorder()
	
	MinimalTheme.reorder()
	