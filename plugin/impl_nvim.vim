
if !exists('*nvim_open_win')
    finish
endif

let s:winidInvalid = 0
function! s:create(popupid, config, frame)
    " {
    "   'bufnr' : '',
    "   'winid' : '',
    " }
    let implState = {}
    let implState['bufnr'] = nvim_create_buf(0, 1)
    let implState['winid'] = nvim_open_win(implState['bufnr'], 0, s:getOption(a:config, a:frame))
    if implState['winid'] == s:winidInvalid
        execute ':bdelete! ' . implState['bufnr']
        return {}
    endif
    call setwinvar(implState['winid'], '&wrap', 0)
    return implState
endfunction

function! s:close(popupid, config, implState)
    call s:hide(a:popupid, a:config, a:implState)
    execute ':bdelete! ' . a:implState['bufnr']
endfunction

function! s:show(popupid, config, implState)
    if a:implState['winid'] == s:winidInvalid
        let a:implState['winid'] = nvim_open_win(a:implState['bufnr'], 0, s:getOption(a:config, ZFPopupState(a:popupid)['frame']))
    endif
endfunction

function! s:hide(popupid, config, implState)
    if a:implState['winid'] != s:winidInvalid
        call nvim_win_close(a:implState['winid'], 1)
        let a:implState['winid'] = s:winidInvalid
    endif
endfunction

function! s:content(popupid, config, implState, content, contentOrig)
    call nvim_buf_set_lines(a:implState['bufnr'], 0, -1, 1, a:content)
endfunction

function! s:config(popupid, config, implState, frame)
    call nvim_win_set_config(a:implState['winid'], s:getOption(a:config, a:frame))
endfunction

function! s:getOption(config, frame)
    let option = {
                \   'col' : a:frame['x'] - 1,
                \   'row' : a:frame['y'] - 1,
                \   'width' : a:frame['width'],
                \   'height' : a:frame['height'],
                \   'relative' : 'editor',
                \   'anchor' : 'NW',
                \   'focusable' : 0,
                \   'style' : 'minimal',
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

