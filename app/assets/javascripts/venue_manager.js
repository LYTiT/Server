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

var venue_messages = {
  add_fields: function(link, association, content, selector) {
    var current_size = $('.list-group.venue_messages_list.messages_list li:visible').size();
    if(current_size < 4) {
      var new_id = new Date().getTime();
      var regexp = new RegExp('new_' + association, 'g')
      $(selector).append(content.replace(regexp, new_id)); 
      $("a[rel~=tooltip], .has-tooltip").tooltip();
    }
    venue_messages.update_section();
  },
  update_section: function() {
    var current_size = $('.list-group.venue_messages_list.messages_list li:visible').size();
    if(current_size >= 4) {
      $('.list-group.venue_messages_list.add_to_list').addClass('hide');
    } else {
      $('.list-group.venue_messages_list.add_to_list').removeClass('hide');
    }
  },
  assign_positions: function() {
    $(".messages_list li.list-group-item").each(function(index, element) {
      $(this).find('.position').val(index);
    })
    return false;
  }
}

$(function(){
  if($('body').hasClass('venue_manager')) {  
    $('.venue_messages_list.messages_list input[type="hidden"]').each(function(){
      $(this).prev().append($(this));
    });
    $('#messages_list').sortable({
      handle: ".move_handle"
    });
    // $('#messages_list').disableSelection();
    $('#hamburger-menu-button').click(function(){
      jPM.on();  
      $('#hamburger-menu-button').unbind('click');
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
    $('.messages_list').on('click', '.delete_button', function() {
      $(this).parent().find('input[type=hidden]').val('1');
      $(this).closest('.fields').hide();
      venue_messages.update_section();
      return false;
    });
    $('.messages_list').on('click', '.message_items .view', function() {
      $(this).parent().find('.edit').removeClass('hide');
      $(this).parent().find('.edit input').focus();
      $(this).addClass('hide');
    });
    $('.messages_list').on('blur', '.message_items .edit input', function() {
      var val = $.trim($(this).val())
      $(this).val(val);
      if($.trim($(this).val()) == "") {

      } else {
        $(this).parent().parent().find('.view').removeClass('hide');
        $(this).parent().parent().find('.view').html(val);
        $(this).parent().addClass('hide');  
      }
    });
    $('.messages_list').on('keyup', '.message_items .edit input', function() {
      var val = $.trim($(this).val())
      $(this).closest('.list-group-item.fields').find('.character_limit')
      $(this).closest('.list-group-item.fields').find('.character_limit span').html(val.length);
    });
  }
})