
function! ZFPopupLog(text)
    if !exists('s:popupId')
        let s:popupId = ZFPopupCreate({
                    \   'pos' : 'right|top',
                    \   'width' : 2.0/5,
                    \   'height' : 1.0/2,
                    \   'x' : 0,
                    \   'y' : 0,
                    \   'wrap' : 1,
                    \   'contentAlign' : 'bottom',
                    \   'contentOffset' : 0,
                    \ })
    endif
    let content = ZFPopupContent(s:popupId)
    if type(a:text) == type([])
        call extend(content, a:text)
    else
        call add(content, a:text)
    endif
    call ZFPopupContent(s:popupId, content)
endfunction

function! ZFPopupLogClear()
    if exists('s:popupId')
        call ZFPopupClose(s:popupId)
        unlet s:popupId
    endif
endfunction

function! ZFPopupClear()
    if has('nvim')
        let toClose = []
        for i in range(1, winnr('$'))
            let winid = win_getid(i)
            let config = nvim_win_get_config(winid)
            if empty(config) || empty(config['relative'])
                continue
            endif
            call add(toClose, winid)
        endfor
        for winid in toClose
            try
                call nvim_win_close(winid, 1)
            endtry
        endfor
    else
        if exists('*popup_clear')
            call popup_clear(1)
        endif
    endif
endfunction
command! -nargs=0 ZFPopupClear :call ZFPopupClear()

