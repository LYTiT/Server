jQuery(document).ready(function($){
	
	$(function() {
	  if($(window).width() <= 1024) {
	    $("img").each(function() {
	      $(this).attr("src", $(this).attr("src").replace("/assets/lists@2x.png", "/assets/lists_m@2x.png"));
	      $(this).attr("src", $(this).attr("src").replace("/assets/pages@2x.png", "/assets/pages_m@2x.png"));
	      $(this).attr("src", $(this).attr("src").replace("/assets/shake@2x.png", "/assets/shake_m@2x.png"));
	    });
	  }
	});

});