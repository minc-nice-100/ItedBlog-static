function getChecked(node) {
    let re = false;
    $('input.' + node).each(function (i) {
        if (this.checked) {
            re = true;
        }
    });
    return re;
}

function timestamp() {
    return new Date().getTime();
}

function em_confirm(id, property, token) {
    let url, msg;
    let text = '删除后可能无法恢复'
    switch (property) {
        case 'article':
            url = 'article.php?action=del&gid=' + id;
            msg = '确定要删除该篇文章吗？';
            break;
        case 'draft':
            url = 'article.php?action=del&draft=1&gid=' + id;
            msg = '确定要删除该篇草稿吗？';
            break;
        case 'tw':
            url = 'twitter.php?action=del&id=' + id;
            msg = '确定要删除该笔记吗？';
            break;
        case 'comment':
            url = 'comment.php?action=del&id=' + id;
            msg = '确定要删除该评论吗？';
            break;
        case 'commentbyip':
            url = 'comment.php?action=delbyip&ip=' + id;
            msg = '确定要删除来自该IP的所有评论吗？';
            break;
        case 'link':
            url = 'link.php?action=dellink&linkid=' + id;
            msg = '确定要删除该链接吗？';
            break;
        case 'navi':
            url = 'navbar.php?action=del&id=' + id;
            msg = '确定要删除该导航吗？';
            break;
        case 'media':
            url = 'media.php?action=delete&aid=' + id;
            msg = '确定要删除该媒体文件吗？';
            break;
        case 'avatar':
            url = 'blogger.php?action=delicon';
            msg = '确定要删除头像吗？';
            break;
        case 'sort':
            url = 'sort.php?action=del&sid=' + id;
            msg = '确定要删除该分类吗？';
            break;
        case 'del_user':
            url = 'user.php?action=del&uid=' + id;
            msg = '确定要删除该用户吗？';
            break;
        case 'forbid_user':
            url = 'user.php?action=forbid&uid=' + id;
            msg = '确定要禁用该用户吗？';
            text = '';
            break;
        case 'tpl':
            url = 'template.php?action=del&tpl=' + id;
            msg = '确定要删除该模板吗？';
            break;
        case 'reset_widget':
            url = 'widgets.php?action=reset';
            msg = '确定要恢复组件设置到初始状态吗？这样会丢失你自定义的组件。';
            text = '';
            break;
        case 'plu':
            url = 'plugin.php?action=del&plugin=' + id;
            msg = '确定要删除该插件吗？';
            break;
        case 'media_sort':
            url = 'media.php?action=del_media_sort&id=' + id;
            msg = '确定要删除该资源分类吗？';
            text = '不会删除分类下资源文件';
            break;
    }
    swal({
        title: msg,
        text: text,
        icon: "warning",
        buttons: ["取消", "确定"],
        dangerMode: true,
    }).then((willDelete) => {
        if (willDelete) {
            window.location = url + '&token=' + token;
        }
    });
}

function focusEle(id) {
    try {
        document.getElementById(id).focus();
    } catch (e) {
    }
}

function hideActived() {
    $(".alert-success").slideUp(300);
    $(".alert-danger").slideUp(300);
}

// Click action of [More Options] 
let icon_mod = "down";

function displayToggle(id) {
    $("#" + id).toggle();
    if (icon_mod === "down") {
        icon_mod = "right";
        $(".icofont-simple-down").attr("class", "icofont-simple-right")
    } else {
        icon_mod = "down";
        $(".icofont-simple-right").attr("class", "icofont-simple-down")
    }

    Cookies.set('em_' + id, icon_mod, {expires: 365})
}

function doToggle(id) {
    $("#" + id).toggle();
}

function insertTag(tag, boxId) {
    var targetinput = $("#" + boxId).val();
    if (targetinput == '') {
        targetinput += tag;
    } else {
        var n = ',' + tag;
        targetinput += n;
    }
    $("#" + boxId).val(targetinput);
    if (boxId == "tag") $("#tag_label").hide();
}

function isalias(a) {
    var reg1 = /^[\u4e00-\u9fa5\w-]*$/;
    var reg2 = /^[\d]+$/;
    var reg3 = /^post(-\d+)?$/;
    if (!reg1.test(a)) {
        return 1;
    } else if (reg2.test(a)) {
        return 2;
    } else if (reg3.test(a)) {
        return 3;
    } else if (a == 't' || a == 'm' || a == 'admin') {
        return 4;
    } else {
        return 0;
    }
}

function checkform() {
    var a = $.trim($("#alias").val());
    var t = $.trim($("#title").val());

    if (typeof articleTextRecord !== "undefined") {  // 提交时，重置原文本记录值，防止出现离开提示
        articleTextRecord = $("textarea[name=logcontent]").text();
    } else {
        pageText = $("textarea").text();
    }
    if (0 == isalias(a)) {
        return true;
    } else {
        alert("链接别名错误");
        $("#alias").focus();
        return false;
    }
}

function checkalias() {
    var a = $.trim($("#alias").val());
    if (1 == isalias(a)) {
        $("#alias_msg_hook").html('<span id="input_error">别名错误，应由字母、数字、下划线、短横线组成</span>');
    } else if (2 == isalias(a)) {
        $("#alias_msg_hook").html('<span id="input_error">别名错误，不能为纯数字</span>');
    } else if (3 == isalias(a)) {
        $("#alias_msg_hook").html('<span id="input_error">别名错误，不能为\'post\'或\'post-数字\'</span>');
    } else if (4 == isalias(a)) {
        $("#alias_msg_hook").html('<span id="input_error">别名错误，与系统链接冲突</span>');
    } else {
        $("#alias_msg_hook").html('');
        $("#msg").html('');
    }
}

function insert_media_img(fileurl, imgsrc) {
    Editor.insertValue('[![](' + imgsrc + ')](' + fileurl + ')\n\n');
}

function insert_media_video(fileurl) {
    Editor.insertValue('<video class=\"video-js\" controls preload=\"auto\" width=\"100%\" data-setup=\'{"aspectRatio":"16:9"}\'> <source src="' + fileurl + '" type=\'video/mp4\' > </video>');
}

function insert_media(fileurl, filename) {
    Editor.insertValue('[' + filename + '](' + fileurl + ')\n\n');
}

function insert_cover(imgsrc) {
    $('#cover_image').attr('src', imgsrc);
    $('#cover').val(imgsrc);
    $('#cover_rm').show();
}

// act 1：auto save 2：save
function autosave(act) {
    var nodeid = "as_logid";
    var timeout = 60000;
    var url = "article_save.php?action=autosave";
    var title = $.trim($("#title").val());
    var cover = $.trim($("#cover").val());
    var alias = $.trim($("#alias").val());
    var sort = $.trim($("#sort").val());
    var postdate = $.trim($("#postdate").val());
    var date = $.trim($("#date").val());
    var logid = $("#as_logid").val();
    var author = $("#author").val();
    var content = Editor.getMarkdown();
    var excerpt = Editor_summary.getMarkdown();
    var tag = $.trim($("#tag").val());
    var top = $("#top").is(":checked") ? 'y' : 'n';
    var sortop = $("#sortop").is(":checked") ? 'y' : 'n';
    var allow_remark = $("#allow_remark").is(":checked") ? 'y' : 'n';
    var password = $.trim($("#password").val());
    var ishide = $.trim($("#ishide").val());
    var token = $.trim($("#token").val());
    var ishide = ishide == "" ? "y" : ishide;
    var querystr = "logcontent=" + encodeURIComponent(content) + "&logexcerpt=" + encodeURIComponent(excerpt) + "&title=" + encodeURIComponent(title) + "&cover=" + encodeURIComponent(cover) + "&alias=" + encodeURIComponent(alias) + "&author=" + author + "&sort=" + sort + "&postdate=" + postdate + "&date=" + date + "&tag=" + encodeURIComponent(tag) + "&top=" + top + "&sortop=" + sortop + "&allow_remark=" + allow_remark + "&password=" + password + "&token=" + token + "&ishide=" + ishide + "&as_logid=" + logid;

    if (alias != '' && 0 != isalias(alias)) {
        $("#msg").show().html("链接别名错误，自动保存失败");
        if (act == 0) {
            setTimeout("autosave(1)", timeout);
        }
        return;
    }
    // 编辑发布状态的文章时不自动保存
    if (act == 1 && ishide == 'n') {
        return;
    }
    // 内容为空时不自动保存
    if (act == 1 && content == "") {
        setTimeout("autosave(1)", timeout);
        return;
    }
    // 距离上次保存成功时间小于一秒时不允许手动保存
    if ((new Date().getTime() - Cookies.get('em_saveLastTime')) < 1000 && act != 1) {
        alert("请勿频繁操作！");
        return;
    }
    var btname = $("#savedf").val();
    $("#savedf").val("正在保存中...");
    $('title').text('[保存中] ' + titleText);
    $("#savedf").attr("disabled", "disabled");
    $.post(url, querystr, function (data) {
        data = $.trim(data);
        var isresponse = /autosave\_gid\:\d+\_df\:\d*\_/;
        if (isresponse.test(data)) {
            var getvar = data.match(/\_gid\:([\d]+)\_df\:([\d]*)\_/);
            var logid = getvar[1];
            var d = new Date();
            var h = d.getHours();
            var m = d.getMinutes();
            var s = d.getSeconds();
            var tm = (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
            $("#save_info").html("保存于：" + tm);
            $('title').text('[保存成功] ' + titleText);
            articleTextRecord = $("textarea[name=logcontent]").text();  // 保存成功后，将原文本记录值替换为现在的文本
            Cookies.set('em_saveLastTime', new Date().getTime());  // 把保存成功时间戳记录（或更新）到 cookie 中
            $("#" + nodeid).val(logid);
            $("#savedf").attr("disabled", false).val(btname);
        } else {
            $("#savedf").attr("disabled", false).val(btname);
            $("#msg").html("网络或系统出现异常...保存可能失败").addClass("alert-danger");
            $('title').text('[保存失败] ' + titleText);
            alert("保存失败，请备份内容和刷新页面后重试！")
        }
    });
    if (act == 1) {
        setTimeout("autosave(1)", timeout);
    }
}

// “页面”的 editor.md 编辑器 Ctrl + S 快捷键的自动保存动作
function pagesave() {
    document.addEventListener('keydown', function (e) {  // 阻止自动保存产生的浏览器默认动作
        if (e.keyCode == 83 && (navigator.platform.match("Mac") ? e.metaKey : e.ctrlKey)) {
            e.preventDefault();
        }
    });

    let url = "page.php?action=save";

    $.post(url, $("#addlog").serialize(), function (data) {
        let titleText = $('title').text();
        $('title').text('[保存成功] ' + titleText);
        setTimeout(function () {
            $('title').text(titleText);
        }, 2000);
    }).fail(function () {
        $('title').text('[保存失败] ' + $('title').text());
        alert("保存失败！")
    });
}

// toggle plugin
$.fn.toggleClick = function () {
    var functions = arguments;
    return this.click(function () {
        var iteration = $(this).data('iteration') || 0;
        functions[iteration].apply(this, arguments);
        iteration = (iteration + 1) % functions.length;
        $(this).data('iteration', iteration);
    });
};

function removeHTMLTag(str) {
    str = str.replace(/<\/?[^>]*>/g, ''); //去除HTML tag
    str = str.replace(/[ | ]*\n/g, '\n'); //去除行尾空白
    str = str.replace(/ /ig, '');
    return str;
}

// 表格全选
$(function () {
    $('#checkAll').click(function (event) {
        let tr_checkbox = $('table tbody tr').find('input[type=checkbox]');
        tr_checkbox.prop('checked', $(this).prop('checked'));
        event.stopPropagation();
    });
    // 点击表格每一行的checkbox，表格所有选中的checkbox数 = 表格行数时，则将表头的‘checkAll’单选框置为选中，否则置为未选中
    $('table tbody tr').find('input[type=checkbox]').click(function (event) {
        let tbr = $('table tbody tr');
        $('#checkAll').prop('checked', tbr.find('input[type=checkbox]:checked').length == tbr.length ? true : false);
        event.stopPropagation();
    });
});

// 卡片全选
$(function () {
    $('#checkAllCard').click(function (event) {
        let card_checkbox = $('.card-body').find('input[type=checkbox]');
        card_checkbox.prop('checked', $(this).prop('checked'));
        event.stopPropagation();
    });
    $('.card-body').find('input[type=checkbox]').click(function (event) {
        let cards = $('.card-body');
        $('#checkAllCard').prop('checked', cards.find('input[type=checkbox]:checked').length == cards.length ? true : false);
        event.stopPropagation();
    });
});

// editor.md 的 js 钩子
var queue = new Array();
var hooks = {
    addAction: function (hook, func) {
        if (typeof (queue[hook]) == "undefined" || queue[hook] == null) {
            queue[hook] = new Array();
        }
        if (typeof func == 'function') {
            queue[hook].push(func);
        }
    }, doAction: function (hook, obj) {
        try {
            for (var i = 0; i < queue[hook].length; i++) {
                queue[hook][i](obj);
            }
        } catch (e) {
        }
    }
}

// 粘贴上传图片函数
function imgPasteExpand(thisEditor) {
    var listenObj = document.querySelector("textarea").parentNode  // 要监听的对象
    var postUrl = './media.php?action=upload';  // emlog 的图片上传地址
    var emMediaPhpUrl = "./media.php?action=lib";  // emlog 的资源库地址,用于异步获取上传后的图片数据

    // 通过动态配置只读模式,阻止编辑器原有的粘贴动作发生,并恢复光标位置
    function preventEditorPaste() {
        let l = thisEditor.getCursor().line;
        let c = thisEditor.getCursor().ch - 3;

        thisEditor.config({readOnly: true,});
        thisEditor.config({readOnly: false,});
        thisEditor.setCursor({line: l, ch: c});
    }

    // 编辑器通过光标处位置前几位来替换文字
    function replaceByNum(text, num) {
        let l = thisEditor.getCursor().line;
        let c = thisEditor.getCursor().ch;

        thisEditor.setSelection({line: l, ch: (c - num)}, {line: l, ch: c});
        thisEditor.replaceSelection(text);
    }

    // 粘贴事件触发
    listenObj.addEventListener("paste", function (e) {
        if ($('.editormd-dialog').css('display') == 'block') return;  // 如果编辑器有对话框则退出
        if (!(e.clipboardData && e.clipboardData.items)) return;

        var pasteData = e.clipboardData || window.clipboardData; // 获取剪切板里的全部内容
        pasteAnalyseResult = new Array;  // 用于储存遍历分析后的结果

        for (var i = 0; i < pasteData.items.length; i++) {  // 遍历分析剪切板里的数据
            var item = pasteData.items[i];

            if ((item.kind == "file") && (item.type.match('^image/'))) {
                var imgData = item.getAsFile();
                if (imgData.size === 0) return;
                pasteAnalyseResult['type'] = 'img';
                pasteAnalyseResult['data'] = imgData;
                break;  // 当粘贴板中有图片存在时,跳出循环
            }
            ;
        }

        if (pasteAnalyseResult['type'] == 'img') {  // 如果剪切板中有图片,上传图片
            preventEditorPaste();
            uploadImg(pasteAnalyseResult['data']);
            return;
        }
    }, false);

    // 上传图片
    function uploadImg(img) {
        var formData = new FormData();
        var imgName = "粘贴上传" + new Date().getTime() + "." + img.name.split(".").pop();

        formData.append('file', img, imgName);
        thisEditor.insertValue("上传中...");
        $.ajax({
            url: postUrl, type: 'post', data: formData, processData: false, contentType: false, xhr: function () {
                var xhr = $.ajaxSettings.xhr();
                if (xhr.upload) {
                    thisEditor.insertValue("....");
                    xhr.upload.addEventListener('progress', function (e) {  // 用以显示上传进度
                        console.log('进度(byte)：' + e.loaded + ' / ' + e.total);
                        let percent = Math.floor(e.loaded / e.total * 100);
                        if (percent < 10) {
                            replaceByNum('..' + percent + '%', 4);
                        } else if (percent < 100) {
                            replaceByNum('.' + percent + '%', 4);
                        } else {
                            replaceByNum(percent + '%', 4);
                        }
                    }, false);
                }
                return xhr;
            }, success: function (result) {
                let imgUrl, thumbImgUrl;
                console.log('上传成功！正在获取结果...');
                $.get(emMediaPhpUrl, function (data) {  // 异步获取结果,追加到编辑器
                    console.log('获取结果成功！');
                    imgUrl = data.match(/[a-zA-z]+:\/[^\s\"\']*/g)[0];
                    thumbImgUrl = data.match(/[a-zA-z]+:\/[^\s\"\']*/g)[1];
                    replaceByNum(`[![](${thumbImgUrl})](${imgUrl})`, 10);  // 这里的数字 10 对应着’上传中...100%‘是10个字符
                })
            }, error: function (result) {
                alert('上传失败,图片类型错误或网络错误');
                replaceByNum('上传失败,图片类型错误或网络错误', 6);
            }
        })
    }
}

// 把粘贴上传图片函数，挂载到位于文章编辑器、页面编辑器处的 js 钩子处
hooks.addAction("loaded", imgPasteExpand);
hooks.addAction("page_loaded", imgPasteExpand);

// 设置界面，如果设置“自动检测地址”，则设置 input 为只读，以表示该项是无效的
$(document).ready(function () {
    // 网页加载完先检查一遍
    if ($("#detect_url").prop("checked")) {
        $("[name=blogurl]").attr("readonly", "readonly")
    }

    $("#detect_url").click(function () {
        if ($(this).prop("checked")) {
            $("[name=blogurl]").attr("readonly", "readonly")
        } else {
            $("[name=blogurl]").removeAttr("readonly")
        }
    })
})

function checkupdate() {
    $("#upmsg").html("").addClass("spinner-border text-primary");
    $.get("./upgrade.php?action=check_update", function (result) {
        if (result.code == 1001) {
            $("#upmsg").html("您的emlog pro尚未注册，<a href=\"auth.php\">去注册</a>").removeClass();
        } else if (result.code == 1002) {
            $("#upmsg").html("已经是最新版本").removeClass();
        } else if (result.code == 1003) {
            $("#upmsg").html("更新服务已到期，<a href=\"https://www.emlog.net/\" target=\"_blank\">登录官网续期</a>").removeClass();
        } else if (result.code == 200) {
            $("#upmsg").html("有可用的新版本 " + result.data.version + "，<a href=\"https://www.emlog.net/docs/#/changelog\" target=\"_blank\">查看更新内容</a>，<a id=\"doup\" href=\"javascript:doup('" + result.data.file + "','" + result.data.sql + "');\">现在更新</a>").removeClass();
        } else {
            $("#upmsg").html("检查失败，可能是网络问题").removeClass();
        }
    });
}

function doup(source, upsql) {
    $("#upmsg").html("正在更新中，请耐心等待").addClass("ajaxload");
    $.get('./upgrade.php?action=update&source=' + source + "&upsql=" + upsql, function (data) {
        $("#upmsg").removeClass();
        if (data.match("succ")) {
            $("#upmsg").html('恭喜您！更新成功了，请<a href="./">刷新页面</a>开始体验新版emlog');
        } else if (data.match("error_down")) {
            $("#upmsg").html('下载更新失败，可能是服务器网络问题');
        } else if (data.match("error_zip")) {
            $("#upmsg").html('解压更新失败，可能是你的服务器空间不支持zip模块');
        } else if (data.match("error_dir")) {
            $("#upmsg").html('更新失败，目录不可写');
        } else {
            $("#upmsg").html('更新失败');
        }
    });
}
