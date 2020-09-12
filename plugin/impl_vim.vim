
if !exists('*popup_create')
    finish
endif

function! s:create(popupId, config, frame)
    " {
    "   'bufnr' : '',
    "   'winid' : '',
    " }
    let implState = {}
    let implState['winid'] = popup_create('', s:getOption(a:config, a:frame))
    if implState['winid'] == 0
        return {}
    endif
    let implState['bufnr'] = winbufnr(implState['winid'])
    return implState
endfunction

function! s:close(popupId, config, implState)
    call popup_close(a:implState['winid'])
endfunction

function! s:show(popupId, config, implState)
    call popup_show(a:implState['winid'])
    call s:config(a:popupId, a:config, a:implState)
endfunction

function! s:hide(popupId, config, implState)
    call popup_hide(a:implState['winid'])
endfunction

function! s:content(popupId, config, implState, content, contentOrig)
    call popup_settext(a:implState['winid'], a:content)
endfunction

function! s:config(popupId, config, implState, frame)
    call popup_setoptions(a:implState['winid'], s:getOption(a:config, a:frame))
endfunction

function! s:getOption(config, frame)
    let option = {
                \   'col' : a:frame['x'],
                \   'line' : a:frame['y'],
                \   'maxwidth' : a:frame['width'],
                \   'minwidth' : a:frame['width'],
                \   'maxheight' : a:frame['height'],
                \   'minheight' : a:frame['height'],
                \   'pos' : 'topleft',
                \   'posinvert' : 0,
                \   'fixed' : 1,
                \   'tabpage' : -1,
                \   'wrap' : 0,
                \   'drag' : 0,
                \   'resize' : 0,
                \   'close' : 'none',
                \   'scrollbar' : 0,
                \ }
    return option
endfunction

let g:ZFPopupImpl = {
            \   'create' : function('s:create'),
            \   'close' : function('s:close'),
            \   'show' : function('s:show'),
            \   'hide' : function('s:hide'),
            \   'content' : function('s:content'),
            \   'config' : function('s:config'),
            \ }

