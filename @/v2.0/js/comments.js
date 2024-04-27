
function comment_post(cid,poster){
   $('#reply-sptitle').text('回复'+poster)
   $('#comment-pid').val(cid)
    $('#cancel-comment-reply-link').show()
    console.log(poster)
    console.log(cid)
}
function comment_quit(){
    $('#comment-pid').val(0)
    $('#cancel-comment-reply-link').hide()
    $('#reply-sptitle').text('发表回复')
}
