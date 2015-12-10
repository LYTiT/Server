jQuery(document).ready(function($){
	//target the entire page, and listen for touch events
	$('html, body').on('touchstart touchmove', function(e){ 
	     //prevent native touch activity like scrolling
	     e.preventDefault(); 
	});
});