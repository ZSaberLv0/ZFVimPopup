
let s:id = ZFPopupCreate({
            \   'pos' : 'cursor|right|bottom',
            \   'width' : 1.0/4,
            \   'height' : 5,
            \   'wrap' : 0,
            \ })

call ZFPopupContent(s:id, split('12345678901234567890abcd', '\zs'))

let timer = 0

function! s:content1(...)
    let content = ZFPopupContent(s:id)
    call add(content, 'zzz')
    call ZFPopupContent(s:id, content)
endfunction
let timer += 1000
call timer_start(timer, function('s:content1'))

function! s:content2(...)
    call ZFPopupContent(s:id, ['1'])
endfunction
let timer += 1000
call timer_start(timer, function('s:content2'))

function! s:hide(...)
    call ZFPopupHide(s:id)
endfunction
let timer += 1000
call timer_start(timer, function('s:hide'))

function! s:show(...)
    call ZFPopupShow(s:id)
endfunction
let timer += 1000
call timer_start(timer, function('s:show'))

function! s:close(...)
    call ZFPopupClose(s:id)
endfunction
let timer += 1000
call timer_start(timer, function('s:close'))

