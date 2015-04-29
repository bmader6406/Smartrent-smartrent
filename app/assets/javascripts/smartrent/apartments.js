// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(function(){
  $('.apartment_listing input').change(function(){
    $('.apartment_listing').submit();
  });
});
