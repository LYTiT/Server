$(function() {
  if($('body').hasClass('splash')) {
    
    // Sign In Button
    $('.login.before .sign_in_button a').click(function() {
      $(this).parents('.login').hide();
      $('.login.after').removeClass('hide');
      return false;
    });

  }
});