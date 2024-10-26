let layer = layui.layer, form = layui.form, laydate = layui.laydate, upload = layui.upload, util = layui.util;
form.verify({
  chinese: function(value, elem) {
   // if (!new RegExp("^.*[\u4e00-\u9fa5\]+.*$").test(value)) {
    if (false) {
      return '必须包含中文';
    }
  },
});
const helper = {
  layon: function () {
    
  }
};
const simplys = {
  nav: function (o) {
    let d = {};
    o = $.extend(d, o || {});
    //nav pc
    if (!theme.isMobile) {
      $('header .nav-items > .item').hover(function () {
        $(this).addClass('active');
      }, function () {
        $(this).removeClass('active');
      })
    }
    // nav xs
    $('header .xs-nav-button').click(function () {
      $('html').toggleClass('nav-open');
    })
    $(document).on('click', '.nav-open .nav-items > .item', function () {
      $(this).toggleClass('show-child');
      $(this).find('.nav-child-box').slideToggle();
    })
    $('header .xs-nav-layer').not('header .right').click(function () {
      $('html').removeClass('nav-open');
    })
  },
  darkmode: function (o) {
    let d = {
      el: '#dark-mode'
    };
    o = $.extend(d, o || {});
    if (!o.el || !$(o.el).length) return;
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    function darkModeHandler() {
      if (!theme.isMobile) return;
      if (mediaQuery.matches) {
        document.documentElement.classList.remove('light');
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
        document.documentElement.classList.add('light');
      }
    }
    darkModeHandler();
    mediaQuery.addListener(darkModeHandler);

    localStorage.getItem('dark-mode') && document.querySelector(o.el).classList.add('on');
    // dark mode
    $(o.el).click(function () {
      if ($('html').hasClass('dark')) {
        $('html').removeClass('dark');
        localStorage.removeItem('dark-mode');
      } else {
        $('html').addClass('dark');
        localStorage.setItem('dark-mode', true);
      }
    })
  },
  gotop: function (o) {
    let d = {
      el: '.sidebar-totop'
    };
    o = $.extend(d, o || {});
    if (!o.el || !$(o.el).length) return;
    let timer = null;
    const totopAttr = () => (document.documentElement.scrollTop || document.body.scrollTop) > 200 ? $(o.el).addClass('active') : $(o.el).removeClass('active');
    totopAttr(), $(document).on('scroll', () => {
      clearTimeout(timer), timer = setTimeout(totopAttr, 80)
    }), $(o.el).on('click', () => window.scrollTo({
      top: 0,
      behavior: 'smooth'
    }))
  },
  clipboard: function (o) {
    let d = {
      el: '.clipboard'
    };
    o = $.extend(d, o || {});
    if (typeof ClipboardJS != 'function') return;
    let clipboard = new ClipboardJS(o.el);
    clipboard.on('success', function (e) {
      layer.msg('复制成功！');
      e.clearSelection();
    });
  },
  switch: function (o) {
    let d = {
      el: '.button-switch'
    };
    o = $.extend(d, o || {});
    if (!o.el || !$(o.el).length) return;
    $(o.el).each(function () {
      if ($(this).prop('disabled')) return;
      $(this).click(function () {
        $(this).toggleClass('on');
      });
    });
  },
  select: function (o) {
    let d = {
      el: '.virtual-select'
    };
    o = $.extend(d, o || {});
    if (!o.el || !$(o.el).length) return;
    $el_select = $(o.el);
    $el_select.click(function (e) {
      e.stopPropagation();
      var select = $(this);
      select.toggleClass('active');
      $(document).on('click', function() {
          $el_select.removeClass('active');
      })
      select.find('.select > .option').click(function (e) {
        e.stopPropagation();
        var option = $(this);
        select.find('.action > .value').html(option.text());
        $el_select.removeClass('active');
      })
    })
  },
  timelife: function (o) {
    let d = {
      $el: $('.aside-timelife-body'),
    };
    o = $.extend(d, o || {});
    if (!o.$el || !o.$el.length) return;
    let data = [{
      title: '今日',
      value: 0,
      unit: '小时',
      percent: '0%',
    }, {
      title: '本周',
      value: 0,
      unit: '天',
      percent: '0%',
    }, {
      title: '本月',
      value: 0,
      unit: '天',
      percent: '0%',
    }, {
      title: '今年',
      value: 0,
      unit: '个月',
      percent: '0%',
    }];
    {
      const thisTime = +new Date;
      const thisDate = new Date((new Date).toLocaleDateString()).getTime();
      data[0].value = parseInt((thisTime - thisDate) / 1e3 / 60 / 60);
      data[0].percent = parseInt(data[0].value / 24 * 100) + "%";
      // console.log(data[0]);
    }
    {
      const week = {
        0: 7,
        1: 1,
        2: 2,
        3: 3,
        4: 4,
        5: 5,
        6: 6
      }
      const thisWeek = week[(new Date).getDay()];
      data[1].value = parseInt(thisWeek);
      data[1].percent = parseInt(thisWeek / 7 * 100) + "%";
      // console.log(data[1]);
    }
    {
      const thisDay = (new Date).getDate();
      const MonthDays = new Date((new Date).getFullYear(), ((new Date).getMonth() + 1), 0).getDate();
      data[2].value = parseInt(thisDay);
      data[2].percent = parseInt(thisDay / MonthDays * 100) + "%";
      // console.log(data[2]);
    }
    {
      const thisMonth = (new Date).getMonth() + 1;
      data[3].value = parseInt(thisMonth);
      data[3].percent = parseInt(thisMonth / 12 * 100) + "%";
      // console.log(data[3]);
    }
    let htmlTimelife = '';
    data.forEach((item, index) => {
      htmlTimelife += `<div class="timelife timelife-${index}"><div class="title-bar"><span class="title">${item.title}</span>已经过去<span class="value mx-5 color-theme">${item.value}</span><span class="unit">${item.unit}</span></div><div class="progress"><div class="progress-bar"><div class="progress-bar-inner" style="width: ${item.percent};"></div></div><div class="progress-percentage">${item.percent}</div></div></div>`;
    })
    o.$el.html(htmlTimelife);
  },
  filmstrip: function (el, o) {
    let d = {
      direction: 'horizontal', //horizontal || vertical
      autoplay: {
        delay: 500000,
        stopOnLastSlide: false,
        disableOnInteraction: false,
      },
      loop: true,
      initialSlide: 0,
      mousewheel: true,
      autoHeight: false,
      setWrapperSize: true,
      roundLengths: true,
      updateOnWindowResize: true,
      updateOnImagesReady: true,
      noSwiping: true,
      noSwipingClass: 'imitate-text',
      focusableElements: 'select, option, textarea, button, video, label',
      pagination: {
        el: '.simply-pagination'
      },
      navigation: {
        prevEl: '.simply-button-prev',
        nextEl: '.simply-button-next',
      },
    };
    if (!el || !$(el) || !$(el).length) return;
    let swiper_filmstrip = new Swiper(el, $.extend(d, o || {}));
  },
  randomCode: function (o) {
    let d = {
      el: '.captcha',
    };
    o = $.extend(d, o || {});
    if (!o.el || !o.el.length) return;
    let src = $(o.el).attr('src');
    $(o.el).attr({
      'src': src + '?' + Math.random(),
    })
    $(document).on('click', o.el, function () {
      $(this).attr({
        'src': src + '?' + Math.random(),
      })
    })
  },
  comment: function () {
    form.on('submit(comment)', function (data) {
      var field = data.field;
      field.resp = 'json';
      $.ajax({
        type: 'POST',
        url: data.form.action,
        data: field,
        async: true,
        beforeSend: function () {
          // 禁用按钮防止重复提交
          layer.msg("提交中...");
          $("#comment-form > div.display-flex.flex-warp.foot > button").addClass('layui-btn-disabled').attr({ disabled: "disabled" });
        },
        success: function (res) {
          turnstile.reset()
          if (typeof (res) === 'string') {
            var pattern = /<div class="main">[\r\n]+<p>(.*?)<\/p>/;
            if(pattern.test(res)) {
              res = res.match(pattern);
              layer.msg(res[1]);
            };
            return;
          }
          if (typeof (res) === 'object' && res.code !== 0) {
            layer.msg('评论失败~请联系管理员');
            return;
          }
          if (typeof (res) === 'object' && res.code == 0) {
            layer.msg('发送成功~');
            setTimeout(function () {
              window.location.reload();
            }, 300);
            return;
          }
        },
        complete: function () {
          turnstile.reset()
          $("#comment-form > div.display-flex.flex-warp.foot > button").removeClass('layui-btn-disabled').removeAttr("disabled");
        },
        error: function (xhr) {
          turnstile.reset()
          layer.msg(xhr.responseJSON.msg);
          simplys.randomCode();
        },
      })
      return false;
    });
    $(document).on('click', '.comment-reply', function () {
      $('input[name=pid]').attr('value', $(this).data('pid'));
      $(this).parent().after($('.comment-post'));
      $('.comment-cancle').css('display', 'flex');
      turnstile.reset()
    })
    $(document).on('click', '.comment-cancle', function () {
      $('input[name=pid]').attr('value', '0');
      $('.comment-cancle').css('display', 'none');
      $('.comment-body').append($('.comment-post'));
      turnstile.reset()
    })
  },
  test: function (o) {
    let d = {
    };
    o = $.extend(d, o || {});
  },
  init: function () {
    this.nav();
    this.darkmode();
    this.gotop();
    this.clipboard();
    this.switch();
    this.select();
    this.timelife();
    this.comment();
    this.randomCode();
  },
  turnstile: function (callback) {
    switch (callback) {
      case "callback":
        var value = "成功";
        break;
      case "error-callback":
        var value = "发生错误";
        break;
      case "expired-callback":
        var value = "质询超时";
        break;
      case "before-interactive-callback":
        var value = "请与质询交互";
        break;
      case "after-interactive-callback":
        var value = "交互完成";
        break;
      case "unsupported-callback":
        var value = "不支持此浏览器";
        break;
      case "timeout-callback":
        var value = "质询超时";
        break;
    };
    var value = "("+value+")";
    $("#comment-form > div.cf-turnstile > span.cf-spinner").text(value);
  },
};

$(function () {
  simplys.init();
  simplys.filmstrip('#swiper-filmstrip-index-1');
});

