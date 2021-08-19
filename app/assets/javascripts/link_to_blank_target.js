/* Allow class="new-window" to have the behavior of opening a link in a new window,
   by ensuring that we use rel="noopener noreferrer" on those links
   (https://medium.com/sedeo/how-to-fix-target-blank-a-security-and-performance-issue-in-web-pages-2118eba1ce2f) 
   in addition to manually adding target="_blank", which gets scrubbed by Rails sanitizer.
*/

A1.openLinksSafelyInNewWindow = function() {
  $('a.new-window').
    attr('target', '_blank').
    attr('rel', 'noopener noreferrer');
}
$(A1.openLinksSafelyInNewWindow);
