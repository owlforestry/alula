#=require jquery
#=require jquery.masonry

jQuery ->
	# jQuery('.paginate .item').wookmark()
	jQuery('.posts').masonry
		itemSelector: '.item'
