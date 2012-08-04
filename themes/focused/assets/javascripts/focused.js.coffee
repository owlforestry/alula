#=require jquery
#=require jquery.masonry

jQuery ->
	# jQuery('.paginate .item').wookmark()
	jQuery('.paginate').masonry
		itemSelector: '.item'
