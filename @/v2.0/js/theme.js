// 关于
console.log('%c iFalse %c ', 'background: linear-gradient(to right, #8183ff, #a1a1f7);color:#fff;border-radius:2px;', '');


// PC端导航栏用户菜单
const user_set_btn = document.querySelector('.nav-bar .admin img');
const user_set_menu = document.querySelector('.nav-bar .user-set');
if(user_set_btn) {
    function remove_set_menu(e) {
        user_set_menu.classList.remove('user-set-open');
        document.removeEventListener("click",remove_set_menu);
    }
    user_set_btn.addEventListener("click",(e)=>{
        e.stopPropagation()
        if(user_set_menu.classList.toggle('user-set-open')) {
            document.addEventListener("click",remove_set_menu);
        }
    })
    user_set_menu.addEventListener("click",(e)=>e.stopPropagation());
}

// 移动端导航栏用户菜单
const user_set_btn_mb = document.querySelector('.nav-bar-mb .admin img');
const user_set_menu_mb = document.querySelector('.nav-bar-mb .user-set');
if(user_set_btn_mb) {
    function remove_set_menu(e) {
        user_set_menu_mb.classList.remove('user-set-open-mb');
        document.removeEventListener("click",remove_set_menu);
    }
    user_set_btn_mb.addEventListener("click",(e)=>{
        e.stopPropagation()
        if(user_set_menu_mb.classList.toggle('user-set-open-mb')) {
            document.addEventListener("click",remove_set_menu);
        }
    })
    user_set_menu_mb.addEventListener("click",(e)=>e.stopPropagation());
}

// 移动端菜单
const menu_mb_open = document.querySelector('#menu-mb-open');
const menu_mb_close = document.querySelector('#menu-mb-close');
const menu_mb = document.querySelector('.menu-mb');
const menu_mb_mask = document.querySelector('.menu-mb-mask');

menu_mb_open.onclick = function() {
    menu_mb.className = 'menu-mb menu-mb-open';
    menu_mb_mask.className = 'menu-mb-mask menu-mb-mask-block';
}
menu_mb_mask.onclick = function() {
    menu_mb.className = 'menu-mb';
    this.className = 'menu-mb-mask';
}
menu_mb_close.onclick = function() {
    menu_mb.className = 'menu-mb';
    menu_mb_mask.className = 'menu-mb-mask';
}

// 目录树菜单按钮
const post_menu_mb_btn = document.querySelector('.post-menu-mb-btn');
const post_menu_mb = document.querySelector('#article-toc-mb');
if(post_menu_mb && post_menu_mb_btn) {
    post_menu_mb_btn.className = 'post-menu-mb-btn post-menu-mb-btn-on';
    function remove_post_menu(e) {
        post_menu_mb.classList.remove('article-toc-mb');
        document.removeEventListener("click",remove_post_menu);
    }
    post_menu_mb_btn.addEventListener("click",(e)=>{
        e.stopPropagation()
        if(post_menu_mb.classList.toggle('article-toc-mb')) {
            document.addEventListener("click",remove_post_menu);
        }
    })
    post_menu_mb.addEventListener("click",(e)=>e.stopPropagation());
}

// 滚动时隐藏header
var header_element = document.querySelectorAll(".header-hidden");
if(header_element) {
    var headroom = []; 
    $(header_element).each(function(i) {
        // headroom[i] = new Headroom(header_element[i]);
        headroom[i] = new Headroom(header_element[i], {
            "tolerance": 5,
            "offset": 205,
          });
        headroom[i].init(); 
    })
}

// 侧边栏搜索
const sidebar_search_btn = document.querySelector('#primary-sidebar .widget_search button');
if(sidebar_search_btn) {
    sidebar_search_btn.innerHTML = '<span class="iconfont icon-sousuo">';
}

// 图片预览
const content_p_img = document.querySelectorAll('.post-content .wp-block-image img');
if(content_p_img) {
	const content_p_a = [];
	for(let i=0; i<content_p_img.length; i++) {
		content_p_a[i] = document.createElement('a');
		content_p_img[i].parentNode.replaceChild(content_p_a[i],content_p_img[i]);
		content_p_a[i].appendChild(content_p_img[i]);
        content_p_a[i].setAttribute('href',content_p_img[i].getAttribute('data-original'));
        content_p_a[i].setAttribute('data-fancybox','gallery');
	}
}

const say_p_img = document.querySelectorAll('.say-post-content p img');
if(say_p_img) {
	const say_p_a = [];
	for(let i=0; i<say_p_img.length; i++) {
		say_p_a[i] = document.createElement('a');
		say_p_img[i].parentNode.replaceChild(say_p_a[i],say_p_img[i]);
		say_p_a[i].appendChild(say_p_img[i]);
        say_p_a[i].setAttribute('href',say_p_img[i].getAttribute('data-original'));
        say_p_a[i].setAttribute('data-fancybox','gallery');
        say_p_a[i].className = 'say-img';
	}
}

const say_dt = document.querySelectorAll('.say-post-content .gallery .gallery-item dt');
const say_dt_img = document.querySelectorAll('.say-post-content .gallery .gallery-item dt img');
if(say_dt_img) {
	const say_dt_img_src = []; 
	for(let i=0; i<say_dt_img.length; i++) {
		say_dt[i].setAttribute('href',say_dt_img[i].getAttribute('data-original'));
        say_dt[i].setAttribute('data-fancybox','gallery');
	}
}

// 缩略图删除延迟加载
const swiper_img = document.querySelectorAll('.swiper .swiper-slide img');
$(swiper_img).each(function(i){
    swiper_img[i].setAttribute('src',swiper_img[i].getAttribute('data-original'));
    swiper_img[i].removeAttribute('data-original');
})

// 黑夜模式按钮
function getCookie(name){
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i].trim();
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}
const night_btn = document.querySelector('.change-night span');
if (getCookie("night") == "1") {
    night_btn.classList.add('icon-rijianmoshixhdpi');
} else {
    night_btn.classList.add('icon-yueduye-yejianmoshi');
}
function nightBtn() {
    if (getCookie("night") == "1") {
        night_btn.classList.add('icon-rijianmoshixhdpi');
        night_btn.classList.remove('icon-yueduye-yejianmoshi');
    } else {
        night_btn.classList.add('icon-yueduye-yejianmoshi');
        night_btn.classList.remove('icon-rijianmoshixhdpi');
    }
}