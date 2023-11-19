// #region Element animator - cycles through a set of elements on a timer (modified from minecraft.gamepedia.com)
// Add the "animated" class to the frame containing the elements to animate.
// Optionally, add the "animated-active" class to the frame to display first.
// Optionally, add the "animated-subframe" class to a frame, and the
// "animated-active" class to a subframe within, in order to designate a set of
// subframes which will only be cycled every time the parent frame is displayed.
// Animations with the "animated-paused" class will be skipped each interval.
( function() {
    var $content = $( '#mw-content-text' );
    var advanceFrame = function(parentElem, parentSelector) {
      var curFrame = parentElem.querySelector(parentSelector + ' > .animated-active');
      $(curFrame).removeClass('animated-active');
      var $nextFrame = $(curFrame && curFrame.nextElementSibling || parentElem.firstElementChild);
      return $nextFrame.addClass('animated-active');
    };

    setInterval(function() {
        if (document.hidden) {
            return;
        }
        $content.find('.animated').each(function() {
            if ($(this).hasClass('animated-paused')) {
                return;
            }

         var $nextFrame = advanceFrame(this, '.animated');
            if ($nextFrame.hasClass('animated-subframe')) {
                advanceFrame($nextFrame[0], '.animated-subframe');
            }
        });
    }, 5000);
} )();
/**
 * Pause animations on mouseover of a designated container (.animated-container)
 *
 * This is so people have a chance to look at the image and click on pages they want to view.
 */
$('#mw-content-text').on('mouseenter mouseleave', '.animated-container', function (e) {
    $(this).find('.animated').toggleClass('animated-paused', e.type === 'mouseenter');
});
// #endregion
