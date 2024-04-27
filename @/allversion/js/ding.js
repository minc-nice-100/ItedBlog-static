$(document).on('click', '.slzanpd', function() {
	var a = $(this),
	id = a.data('slzanpd');
	if (slzanpd_check(id)) {
		alert('您已赞过本文！');
	} else {
		$.post('', {
			plugin: 'slzanpd',
			action: 'slzan',
			id: id
		},
		function(b) {
			a.find('u').html(b);
			slzanpd_(a);
		});
    location.reload();
	}
});
function slzanpd_check(id) {
	return new RegExp('slzanpd_' + id + '=true').test(document.cookie);
}
$('[data-slzanpd]').each(function() {
	var a = $(this),
	id = a.data('slzanpd');
	if (slzanpd_check(id)) {
		slzanpd_(a);
	} else {
		a.attr('title', '点赞，收藏、好耶！')
	}
});
function slzanpd_(a) {
	a.css('cursor', 'not-allowed').attr('title', '您已赞过本文！');
}