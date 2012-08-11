#=require jquery
#=require jquery.fancybox

jQuery ->
	if $.getDevicePixelRatio() > 1
		$(".fancybox").each ->
			if $(this).data('retina')
				$(this).attr 'href', $(this).data 'retina'
	
	$(".fancybox").fancybox
		beforeLoad: ->
			if @element.attributes['data-width']
				@maxWidth = @element.attributes['data-width'].value
			if @element.attributes['data-height']
				@maxHeight = @element.attributes['data-height'].value
