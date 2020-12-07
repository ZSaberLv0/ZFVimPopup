
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

