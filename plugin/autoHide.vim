
if !exists('##WinScrolled')
            \ || !exists('*timer_start')
            \ || get(g:, 'ZFPopup_autoHide', 500) <= 0
    finish
endif

augroup ZF_PopupAutoHide_augroup
    autocmd!
    autocmd CursorMoved,VimResized,WinScrolled * call ZF_PopupAutoHide_update()
augroup END

function! ZF_PopupAutoHide_updateAction(...)
    let s:updateTaskId = -1
    for popupId in ZFPopupList()
        let state = ZFPopupState(popupId)
        if state['show']
            call ZFPopupShow(popupId)
        endif
    endfor
endfunction
function! ZF_PopupAutoHide_update()
    if get(s:, 'updateTaskId', -1) != -1
        call timer_stop(s:updateTaskId)
    else
        for popupId in ZFPopupList()
            let state = ZFPopupState(popupId)
            if state['show']
                call ZFPopupHide(popupId)
                let state['show'] = 1
            endif
        endfor
    endif
    let s:updateTaskId = timer_start(get(g:, 'ZFPopup_autoHide', 500), function('ZF_PopupAutoHide_updateAction'))
endfunction

