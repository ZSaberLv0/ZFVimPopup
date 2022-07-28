
if !exists('*nvim_open_win')
    finish
endif

" https://github.com/neovim/neovim/issues/11440
if has('nvim') && !has('nvim-0.7') && !get(g:, 'ZFPopup_nvim_enableOnOldVer', 0)
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

let s:bufnrInvalid = 0
let s:winidInvalid = 0

function! s:create(popupId, config, frame)
    " {
    "   'bufnr' : '',
    "   'winid' : '',
    "   'showing' : 0/1',
    "   'ownerTab' : '',
    " }
    let implState = {
                \   'bufnr' : s:bufnrInvalid,
                \   'winid' : s:winidInvalid,
                \ }
    try
        silent! let implState['bufnr'] = nvim_create_buf(0, 1)
        silent! let implState['winid'] = nvim_open_win(implState['bufnr'], 0, s:getOption(a:config, a:frame))
    catch
    endtry
    if implState['bufnr'] == s:bufnrInvalid || implState['winid'] == s:winidInvalid
        call s:ensureCloseBuf(implState['bufnr'])
        call s:ensureCloseWin(implState['winid'])
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
    call s:ensureCloseBuf(a:implState['bufnr'])
endfunction

function! s:show(popupId, config, implState)
    let a:implState['showing'] = 1
    let a:implState['ownerTab'] = tabpagenr()
    call s:verifyWin(a:implState)
    call s:doShow(a:popupId, a:config, a:implState)
endfunction
function! s:doShow(popupId, config, implState)
    if a:implState['winid'] == s:winidInvalid
        try
            silent! let a:implState['winid'] = nvim_open_win(a:implState['bufnr'], 0, s:getOption(a:config, ZFPopupState(a:popupId)['frame']))
            call setwinvar(a:implState['winid'], 'ZFPopupWin', 1)
        catch
        endtry
    endif
endfunction

function! s:hide(popupId, config, implState)
    let a:implState['showing'] = 0
    call s:verifyWin(a:implState)
    call s:doHide(a:popupId, a:config, a:implState)
endfunction
function! s:doHide(popupId, config, implState)
    if a:implState['winid'] != s:winidInvalid
        call s:ensureCloseWin(a:implState['winid'])
        let a:implState['winid'] = s:winidInvalid
    endif
endfunction

function! s:content(popupId, config, implState, content, contentOrig)
    try
        silent! call nvim_buf_set_lines(a:implState['bufnr'], 0, -1, 1, a:content)
    catch
    endtry
endfunction

function! s:config(popupId, config, implState, frame)
    call s:verifyWin(a:implState)
    if a:implState['winid'] == s:winidInvalid
        try
            silent! let a:implState['winid'] = nvim_open_win(a:implState['bufnr'], 0, s:getOption(a:config, ZFPopupState(a:popupId)['frame']))
        catch
        endtry
    endif
    try
        silent! call nvim_win_set_config(a:implState['winid'], s:getOption(a:config, a:frame))
        silent! call setwinvar(a:implState['winid'], '&wrap', a:config['wrap'])
    catch
    endtry
endfunction

function! s:verifyWin(implState)
    try
        call nvim_win_get_buf(a:implState['winid'])
    catch
        let a:implState['winid'] = s:winidInvalid
    endtry
endfunction

function! s:updateAllWinDelay(...)
    for state in values(s:allState)
        let implState = state['implState']
        call s:verifyWin(implState)
        if (implState['winid'] != s:winidInvalid) != (implState['showing'] == 1)
            if implState['showing']
                noautocmd call s:doShow(state['popupId'], state['config'], implState)
            else
                noautocmd call s:doHide(state['popupId'], state['config'], implState)
            endif
        elseif implState['ownerTab'] != tabpagenr()
            noautocmd call s:doHide(state['popupId'], state['config'], implState)
            noautocmd call s:doShow(state['popupId'], state['config'], implState)
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
    autocmd BufModifiedSet,BufLeave,BufUnload,TabLeave * call s:tmpHideAll()
augroup END

function! s:tmpHideAll()
    for state in values(s:allState)
        let implState = state['implState']
        call s:verifyWin(implState)
        noautocmd call s:doHide(state['popupId'], state['config'], implState)
    endfor
    call s:closeAllFloatWin()
    if get(s:, 'tmpHideAllRestoreTaskId', -1) == -1 && has('timers')
        let s:tmpHideAllRestoreTaskId = timer_start(200, function('s:tmpHideAllRestore'))
    endif
endfunction
function! s:tmpHideAllRestore(...)
    let s:tmpHideAllRestoreTaskId = -1
    call s:updateAllWinDelay()
endfunction
function! s:closeAllFloatWin()
    if !exists('*nvim_win_get_config')
        return
    endif
    for i in range(1, winnr('$'))
        let id = win_getid(i)
        let config = nvim_win_get_config(id)
        if empty(config) || empty(config['relative'])
            continue
        endif
        if !getwinvar(id, 'ZFPopupWin', 0)
            continue
        endif

        call s:ensureCloseWin(id)
    endfor
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

" ============================================================
" https://github.com/neovim/neovim/issues/11387
" https://github.com/neovim/neovim/issues/13628
function! s:ensureCloseWin(winid)
    if a:winid == s:winidInvalid
        return
    endif
    try
        call nvim_win_close(a:winid, 1)
        if nvim_win_is_valid(a:winid)
            call s:invalidWinAdd(a:winid)
        endif
    catch
        call s:invalidWinAdd(a:winid)
    endtry
endfunction

if !exists('g:invalidWinList')
    let g:invalidWinList = []
endif
function! s:invalidWinAdd(winid)
    if !has('timers')
        return
    endif
    call add(g:invalidWinList, a:winid)
    if len(g:invalidWinList) != 1
        return
    endif
    call timer_start(500, function('s:invalidWinClear'))
endfunction
function! s:invalidWinClear(...)
    let i = len(g:invalidWinList) - 1
    while i >= 0
        try
            if nvim_win_is_valid(g:invalidWinList[i])
                call s:invalidWinAdd(g:invalidWinList[i])
            endif
            silent! call nvim_win_close(g:invalidWinList[i], 1)
            call remove(g:invalidWinList, i)
        catch
        endtry
        let i -= 1
    endwhile
    if !empty(g:invalidWinList)
        call timer_start(500, function('s:invalidWinClear'))
    endif
endfunction

" ============================================================
function! s:ensureCloseBuf(bufnr)
    if a:bufnr == s:bufnrInvalid
        return
    endif
    try
        execute ':bdelete! ' . a:bufnr
    catch
        call s:invalidBufAdd(a:bufnr)
    endtry
endfunction

if !exists('g:invalidBufList')
    let g:invalidBufList = []
endif
function! s:invalidBufAdd(bufnr)
    if !has('timers')
        return
    endif
    call add(g:invalidBufList, a:bufnr)
    if len(g:invalidBufList) != 1
        return
    endif
    call timer_start(500, function('s:invalidBufClear'))
endfunction
function! s:invalidBufClear(...)
    let i = len(g:invalidBufList) - 1
    while i >= 0
        try
            silent! execute ':bdelete! ' . g:invalidBufList[i]
            call remove(g:invalidBufList, i)
        catch
        endtry
        let i -= 1
    endwhile
    if !empty(g:invalidBufList)
        call timer_start(500, function('s:invalidBufClear'))
    endif
endfunction
" ============================================================

let g:ZFPopupImpl = {
            \   'create' : function('s:create'),
            \   'close' : function('s:close'),
            \   'show' : function('s:show'),
            \   'hide' : function('s:hide'),
            \   'content' : function('s:content'),
            \   'config' : function('s:config'),
            \ }

