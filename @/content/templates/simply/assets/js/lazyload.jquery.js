(function($) {
  $.fn.lazyLoad = function() {
    var observer = new IntersectionObserver(function(entries, self) {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          var $img = $(entry.target);
          var dataSrc = $img.data('src');
          if (dataSrc) {
            $img.attr('src', dataSrc);
            $img.removeAttr('data-src');
            self.unobserve(entry.target);
          }
        }
      });
    }, { rootMargin: '50px 0px', threshold: 0 });

    this.each(function() {
      observer.observe(this);
    });

    return this;
  };
})(jQuery);