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
  $('#hamburger-menu-button').click(function(){
    jPM.on();  
    $("#hamburger-menu-button").unbind('click');
  });
  $('.venue-selector a').click(function(){
    return false;
  });
})