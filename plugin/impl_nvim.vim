
if !exists('*nvim_open_win')
    finish
endif

" {
"   popupId : {
"     'popupId' : '',
"     'config' : '',
"     'implState' : '',
"   },
" }
if !exists('s:allState')
    let s:allState = {}
endif

let s:winidInvalid = 0
function! s:create(popupId, config, frame)
    " {
    "   'bufnr' : '',
    "   'winid' : '',
    "   'showing' : 0/1',
    "   'ownerTab' : '',
    " }
    let implState = {}
    let implState['bufnr'] = nvim_create_buf(0, 1)
    let implState['winid'] = nvim_open_win(implState['bufnr'], 0, s:getOption(a:config, a:frame))
    if implState['winid'] == s:winidInvalid
        execute ':bdelete! ' . implState['bufnr']
        return {}
    endif
    let implState['showing'] = 1
    let implState['ownerTab'] = tabpagenr()
    let s:allState[a:popupId] = {
                \   'popupId' : a:popupId,
                \   'config' : a:config,
                \   'implState' : implState,
                \ }
    return implState
endfunction

function! s:close(popupId, config, implState)
    silent! unlet s:allState[a:popupId]
    let a:implState['showing'] = 0
    call s:verifyWin(a:implState)
    call s:hide(a:popupId, a:config, a:implState)
    execute ':bdelete! ' . a:implState['bufnr']
endfunction

function! s:show(popupId, config, implState)
    let a:implState['showing'] = 1
    let a:implState['ownerTab'] = tabpagenr()
    call s:verifyWin(a:implState)
    if a:implState['winid'] == s:winidInvalid
        let a:implState['winid'] = nvim_open_win(a:implState['bufnr'], 0, s:getOption(a:config, ZFPopupState(a:popupId)['frame']))
    endif
endfunction

function! s:hide(popupId, config, implState)
    let a:implState['showing'] = 0
    call s:verifyWin(a:implState)
    if a:implState['winid'] != s:winidInvalid
        call nvim_win_close(a:implState['winid'], 1)
        let a:implState['winid'] = s:winidInvalid
    endif
endfunction

function! s:content(popupId, config, implState, content, contentOrig)
    call nvim_buf_set_lines(a:implState['bufnr'], 0, -1, 1, a:content)
endfunction

function! s:config(popupId, config, implState, frame)
    call s:verifyWin(a:implState)
    if a:implState['winid'] == s:winidInvalid
        let a:implState['winid'] = nvim_open_win(a:implState['bufnr'], 0, s:getOption(a:config, ZFPopupState(a:popupId)['frame']))
    endif
    call nvim_win_set_config(a:implState['winid'], s:getOption(a:config, a:frame))
    call setwinvar(a:implState['winid'], '&wrap', a:config['wrap'])
endfunction

function! s:verifyWin(implState)
    try
        call nvim_win_get_buf(a:implState['winid'])
    catch /E5555:/
        let a:implState['winid'] = s:winidInvalid
    endtry
endfunction

function! s:updateAllWinDelay(...)
    for state in values(s:allState)
        let implState = state['implState']
        call s:verifyWin(implState)
        if (implState['winid'] != s:winidInvalid) != (implState['showing'] == 1)
            if implState['showing']
                noautocmd call s:show(state['popupId'], state['config'], implState)
            else
                noautocmd call s:hide(state['popupId'], state['config'], implState)
            endif
        elseif implState['ownerTab'] != tabpagenr()
            noautocmd call s:hide(state['popupId'], state['config'], implState)
            noautocmd call s:show(state['popupId'], state['config'], implState)
        endif
    endfor
endfunction
function! s:updateAllWin()
    if has('timers')
        call timer_start(0, function('s:updateAllWinDelay'))
    else
        call s:updateAllWinDelay()
    endif
endfunction
augroup ZF_Popup_nvim_fix
    autocmd!
    autocmd TabNew,TabClosed * call s:updateAllWin()
augroup END

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

