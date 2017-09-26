(function($) {
  $(function() {
    $('.js-headerSearchFormToggle').toggleHeaderSearchFormListener();

  });

  $.fn.toggleHeaderSearchFormListener = function(el) {
    function makeHeaderSearchToggleCallback($element) {
      return function onClick(e) {

        // $element.parents('.js-headerSearchToggle').toggleClass('-visible');

        if ( $element.find('.js-headerSearchForm').hasClass('-visible') === true ) {
          $element.find('.js-headerSearchForm').removeClass('-visible').blur();
        } else {
          $element.find('.js-headerSearchForm').addClass('-visible').focus();
        }

        $element.toggleClass('-visible').find('.js-headerSearchForm input').focus();
        // set the old hidden one to show
        $element.find('.js-headerSearchFormButton.-hidden').attr('aria-hidden', null);
        $element.find('.js-headerSearchFormButton').toggleClass('-hidden');
        // set the new hidden one to hide
        $element.find('.js-headerSearchFormButton.-hidden').attr('aria-hidden', true);
      }
    };

    return $(this).each(function() {
      $('.js-headerSearchFormButton').on( 'click', makeHeaderSearchToggleCallback($(this)) );
    });
  };

})(jQuery);