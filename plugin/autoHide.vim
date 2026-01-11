
if get(g:, 'ZFPopup_autoHide', 500) <= 0
            \ || !exists('*timer_start')
    finish
endif

augroup ZF_PopupAutoHide_augroup
    autocmd!
    autocmd CursorMoved,VimResized * call ZF_PopupAutoHide_update()
    if exists('##WinScrolled')
        autocmd WinScrolled * call ZF_PopupAutoHide_update()
    endif
augroup END

function! ZF_PopupAutoHide_updateAction(...)
    let s:updateTaskId = -1
    for popupId in ZFPopupList()
        let state = ZFPopupState(popupId)
        if state['showing']
            let state['tmpHide'] = 0
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
            if state['showing']
                call ZFPopupHide(popupId)
                let state['showing'] = 1
                let state['tmpHide'] = 1
            endif
        endfor
    endif
    let s:updateTaskId = timer_start(get(g:, 'ZFPopup_autoHide', 500), function('ZF_PopupAutoHide_updateAction'))
endfunction

