"use strict";
const aioTheme = {
    init: () => {
    },
    initLoaded: () => {
        aioTheme.hideHeader();
        aioTheme.progressPageLoad();
        aioTheme.navCanvas();
        aioTheme.popovers();
        aioTheme.tooltip();
        aioTheme.validation();
        aioTheme.toast();
        aioTheme.search();
        aioTheme.clipboard();
        aioTheme.comment();
    },
    hideHeader: () => {
        let scrollTopInit = 0;
        let scrollTopTemp = 0;
        const eleHeader = document.querySelector("header");
        if (null != eleHeader) {
            window.addEventListener("scroll", (function (o) {
                scrollTopInit = document.body.scrollTop || document.documentElement.scrollTop;
                if (scrollTopInit >= scrollTopTemp && scrollTopInit > 100) {
                    eleHeader.classList.add("header-transform");
                } else {
                    eleHeader.classList.remove("header-transform");
                }
                setTimeout(() => {
                    scrollTopTemp = scrollTopInit;
                }, 10);
            }));
        }
    },
    progressPageLoad: () => {
        const eleBtnScroll = document.querySelector("#sidebar-button-totop");
        if (null != eleBtnScroll) {
            const showScroll = () => {
                (document.body.scrollTop || document.documentElement.scrollTop) >= 50 ? eleBtnScroll.classList.add("active-progress") : eleBtnScroll.classList.remove("active-progress");
            }

            showScroll();

            window.addEventListener("scroll", (function (o) {
                showScroll();
            }));
            eleBtnScroll.addEventListener("click", (function (e) {
                e.preventDefault();
                window.scroll({
                    top: 0,
                    left: 0,
                    behavior: "smooth"
                })
            }))
        }
    },
    navCanvas: () => {
        const eleOffCanvas = document.getElementById("offcanvasMenu");
        if (null != eleOffCanvas) {
            eleOffCanvas.addEventListener("show.bs.offcanvas", event => {
                document.documentElement.classList.add("burger-open");
            })
            document.querySelectorAll(".nav-list li").forEach(element => {
                let eleNavItem = element.querySelector(".nav-child-box");
                if (null != eleNavItem) {
                    element.addEventListener("click", () => {
                        const siblings = helper.siblings(element);
                        siblings.forEach(sibling => {
                            sibling.classList.remove("active");
                        })
                        element.classList.toggle("active");
                    })
                }
            })
            eleOffCanvas.addEventListener("hidden.bs.offcanvas", event => {
                document.documentElement.classList.remove("burger-open");
            })
        }
    },
    popovers: () => {
        [...document.querySelectorAll("[data-bs-toggle=\"popover\"]")].map((e => new bootstrap.Popover(e)))
    },
    tooltip: () => {
        [...document.querySelectorAll("[data-bs-toggle=\"tooltip\"]")].map((e => new bootstrap.Tooltip(e)))
    },
    validation: () => {
        const elesNeedsValidation = document.querySelectorAll(".needs-validation");
        Array.from(elesNeedsValidation).forEach((element => {
            element.addEventListener("submit", (e => {
                element.checkValidity() || (e.preventDefault(), e.stopPropagation());
                element.classList.add("was-validated")
            }), !1)
        }))
    },
    toast: () => {
        const eleleLiveToastBtn = document.getElementById("liveToastBtn"),
            eleLiveToast = document.getElementById("liveToast");
        if (eleleLiveToastBtn) {
            const toastInstance = bootstrap.Toast.getOrCreateInstance(eleLiveToast);
            eleleLiveToastBtn.addEventListener("click", (() => {
                toastInstance.show()
            }))
        }
    },
    search: () => {
        $(".aio-search-clear").click(function (e) {
            const eleSearchForm = $(this).parents("form"), eleSearchKeyword = eleSearchForm.find(".aio-search-keyword");
            if (eleSearchKeyword.val().length > 0) {
                console.log(eleSearchKeyword.val())
                eleSearchKeyword.val("");
                eleSearchForm.submit();
            }
        })
    },
    clipboard: () => {
        if (typeof ClipboardJS != 'function') return;
        const clipboard = new ClipboardJS(".clipboard");
        clipboard.on("success", function (e) {
            viewer.msg("复制成功");
        })
    },
    comment: () => {
        $(document).on("click", ".comment-reply", function () {
            $("#comment-form input[name=pid]").attr("value", $(this).data("pid"));
            $(this).parent().after($(".comment-post"));
            $(".comment-cancle").css("display", "block");
        })
        $(document).on("click", ".comment-cancle", function () {
            $("#comment-form input[name=pid]").attr("value", 0);
            $(".comment-cancle").css("display", "none");
            $(".comment-post-box").append($(".comment-post"));
        })
    },
};

const aioPlugin = {
    plyr: () => {
        const plyr_i18n = {
            restart: "重播",
            rewind: "后退 {seektime}s",
            play: "播放",
            pause: "暂停",
            fastForward: "快进 {seektime}s",
            seek: "Seek",
            seekLabel: "{currentTime} of {duration}",
            played: "Played",
            buffered: "缓冲完成",
            currentTime: "Current time",
            duration: "时长",
            volume: "音量",
            mute: "静音",
            unmute: "取消静音",
            enableCaptions: "启用字幕",
            disableCaptions: "禁用字幕",
            download: "下载",
            enterFullscreen: "全屏",
            exitFullscreen: "退出",
            frameTitle: "正在播放：{title}",
            captions: "标题",
            settings: "设置",
            pip: "PIP",
            menuBack: "返回",
            speed: "播放速度",
            normal: "正常",
            quality: "质量",
            loop: "循环播放",
            start: "开始",
            end: "结束",
            all: "全部",
            reset: "重置",
            disabled: "禁用",
            enabled: "开启",
            advertisement: "广告",
            qualityBadge: {
                2160: "4K",
                1440: "HD",
                1080: "HD",
                720: "HD",
                576: "SD",
                480: "SD",
            },
        };
        const players = Array.from(document.querySelectorAll("audio, video")).map((element) => {
            const player = new Plyr(element, {
                ratio: "16:9",
                i18n: plyr_i18n,
            })
            const url = element.getAttribute("src") ? element.getAttribute("src") : element.querySelector("source").getAttribute("src");
            if (url.indexOf(".m3u8") > -1) {
                if (!Hls.isSupported()) {
                    element.src = url;
                } else {
                    const hls = new Hls();
                    hls.loadSource(url);
                    hls.attachMedia(element);
                    window.hls = hls;
                }
            }
        });

        const medias = Array.prototype.slice.apply(document.querySelectorAll("audio, video"));
        medias.forEach((media) => {
            media.addEventListener("play", (event) => {
                medias.forEach((media) => {
                    if (event.target != media) media.pause();
                });
            });
        });
    },
};

aioTheme.init();

window.addEventListener("DOMContentLoaded", () => {
    aioTheme.initLoaded();
})