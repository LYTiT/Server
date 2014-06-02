var jPM = $.jPanelMenu({
  menu: '#custom-menu-selector',
  trigger: '#hamburger-menu-button',
  openPosition: '170px',
  afterOpen: function() {
    $('#hamburger-menu-button').addClass('active');
  },
  afterClose: function() {
    $('#hamburger-menu-button').removeClass('active');
  }
});

$(function(){
  if($('body').hasClass('venue_manager')) {  
    $('#hamburger-menu-button').click(function(){
      jPM.on();  
      $("#hamburger-menu-button").unbind('click');
    });
    $('.venue-selector a').click(function(){
      $('.modal-backdrop').removeClass('hide').addClass('in');
      $('.venue-selector-container ul.list-group').show();
      return false;
    });
    $('.venue-selector-container ul.list-group li a, .modal-backdrop').click(function(){
      $('.modal-backdrop').addClass('hide').removeClass('in');
      $('.venue-selector-container ul.list-group').hide();
    });
  }
})