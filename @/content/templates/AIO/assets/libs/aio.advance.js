"use strict";

const helper = {
    hasClass: (el, className) => [].slice.call(el.classList).includes(className),
    siblings: (element) => Array.from(element.parentNode.children).filter(child => child !== element),
    detectMobile: () => /windows phone|iphone|android|HarmonyOS|SymbianOS/gi.test(window.navigator.userAgent),
    detectIE: () => {
        let ua = window.navigator.userAgent,
            ie = ua.indexOf("MSIE ");
        if (ie > 0) {
            return parseInt(ua.substring(ie + 5, ua.indexOf(".", ie)), 10);
        }
        if (ua.indexOf("Trident/") > 0) {
            let rv = ua.indexOf("rv:");
            return parseInt(ua.substring(rv + 3, ua.indexOf(".", rv)), 10);
        }
        let edge = ua.indexOf(".Edge/");
        return edge > 0 && parseInt(ua.substring(edge + 5, ua.indexOf(".", edge)), 10);
    },
    getURLParameters: (url) => (url.match(/([^?=&]+)(=([^&]*))/g) || []).reduce(
        (a, v) => ((a[v.slice(0, v.indexOf("="))] = v.slice(v.indexOf("=") + 1)), a), {}
    ),
    formToObject: (form) => Array.from(new FormData(form)).reduce(
        (acc, [key, value]) => ({
            ...acc,
            [key]: value
        }),
        {}
    ),
    onClickOutside: (element, callback) => {
        document.addEventListener("click", e => {
            if (!element.contains(e.target)) callback();
        })
    },
};

const viewer = {
    msg: (content) => {
        const attrid = "aio-msg";
        if (!content || document.getElementById(attrid)) return;
        const div = document.createElement("div");
        div.id = attrid;
        div.setAttribute("class", "aio-msg");
        div.innerHTML = content;
        document.body.appendChild(div);
        
        const eleMsg = document.getElementById(attrid);

        eleMsg.style.position = "fixed";
        eleMsg.style.zIndex = "1060";
        eleMsg.style.left = (document.documentElement.clientWidth - eleMsg.clientWidth) / 2 + "px";
        eleMsg.style.bottom = (document.documentElement.clientHeight - eleMsg.clientHeight) / 2 + "px";

        eleMsg.classList.add("show");

        setTimeout(() => {
            eleMsg.classList.remove("show");
            setTimeout(() => {
                eleMsg.parentNode.removeChild(eleMsg);
            }, 300);
        }, 3000);
    }
};

(() => {
    helper.detectIE() && alert("当前站点不支持IE浏览器（或您开启了兼容模式），请使用其他浏览器访问（或关闭兼容模式）。");
})();

(() => {
    const storedTheme = localStorage.getItem("theme");
    const getPreferredTheme = () => {
        if (storedTheme) {
            return storedTheme;
        }
        return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    }

    const setTheme = function (theme) {
        if (theme == "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches) {
            document.documentElement.setAttribute("data-bs-theme", "dark");
            document.querySelector("meta[name=\"theme-color\"]").setAttribute("content", "#212529");
        } else {
            document.documentElement.setAttribute("data-bs-theme", theme);
            const themeContentColor = theme == "dark" ? "#212529" : "#ffffff";
            document.querySelector("meta[name=\"theme-color\"]").setAttribute("content", themeContentColor);
        }
    }

    setTheme(getPreferredTheme());

    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
        if (storedTheme !== "light" || storedTheme !== "dark") {
            setTheme(getPreferredTheme());
        }
    })

    window.addEventListener("DOMContentLoaded", () => {
        document.querySelector("#sidebar-button-theme").addEventListener("click", () => {
            const theme = localStorage.getItem("theme") == "dark" ? "light" : "dark";
            localStorage.setItem("theme", theme);
            setTheme(theme);
        })
    })
})();
