
function! ZF_PopupContentFix(popupid, state)
    if a:state['config']['wrap']
        return s:wrapContent(a:state['config'], a:state['content'], a:state['frame']['width'], a:state['frame']['height'])
    else
        return s:nowrapContent(a:state['config'], a:state['content'], a:state['frame']['width'], a:state['frame']['height'])
    endif
endfunction

function! s:nowrapContent(config, contentOrig, width, height)
    let content = []
    let offset = a:config['contentOffset']
    let len = len(a:contentOrig)
    if a:config['contentAlign'] != 'bottom'
        if offset < 0
            if (0 - offset) < a:height
                for i in range(0 - offset)
                    call add(content, '')
                endfor
                for i in range(a:height + offset)
                    if i >= len
                        break
                    endif
                    call add(content, a:contentOrig[i])
                endfor
            endif
        else
            for i in range(a:height)
                if i + offset >= len
                    break
                endif
                call add(content, a:contentOrig[i + offset])
            endfor
        endif
    else
        if offset < 0
            if (0 - offset) < a:height
                for i in range(0 - offset)
                    call add(content, '')
                endfor
                for i in range(a:height + offset)
                    if i >= len
                        break
                    endif
                    call insert(content, a:contentOrig[len - 1 - i], 0)
                endfor
            endif
        else
            for i in range(a:height)
                if len - 1 - (i + offset) < 0
                    break
                endif
                call insert(content, a:contentOrig[len - 1 - (i + offset)], 0)
            endfor
        endif
    endif
    return content
endfunction

function! s:wrapContent(config, contentOrig, width, height)
    let content = []
    let offset = a:config['contentOffset']
    let len = len(a:contentOrig)
    if a:config['contentAlign'] != 'bottom'
        if offset < 0
            if (0 - offset) < a:height
                for i in range(0 - offset)
                    call add(content, '')
                endfor
                let iLine = 0
                while iLine < len
                    call s:insertWrapLines(content, len(content), a:contentOrig[iLine], a:width)
                    let iLine += 1
                    if len(content) >= a:height
                        if len(content) > a:height
                            call remove(content, a:height, -1)
                        endif
                        break
                    endif
                endwhile
            endif
        else
            let iLine = 0
            while iLine < len
                call s:insertWrapLines(content, len(content), a:contentOrig[iLine], a:width)
                let iLine += 1
                if len(content) >= a:height + offset
                    if offset > 0
                        call remove(content, 0, offset - 1)
                    endif
                    if len(content) > a:height
                        call remove(content, a:height, -1)
                    endif
                    break
                endif
            endwhile
        endif
    else
        if offset < 0
            if (0 - offset) < a:height
                for i in range(0 - offset)
                    call add(content, '')
                endfor
                let iLine = len(a:contentOrig) - 1
                while iLine >= 0
                    call s:insertWrapLines(content, 0, a:contentOrig[iLine], a:width)
                    let iLine -= 1
                    if len(content) >= a:height
                        if len(content) > a:height
                            call remove(content, 0, len(content) - a:height - 1)
                        endif
                        break
                    endif
                endwhile
            endif
        else
            let iLine = len(a:contentOrig) - 1
            while iLine >= 0
                call s:insertWrapLines(content, 0, a:contentOrig[iLine], a:width)
                let iLine -= 1
                if len(content) >= a:height + offset
                    if offset > 0
                        call remove(content, len(content) - offset, -1)
                    endif
                    if len(content) > a:height
                        call remove(content, 0, len(content) - a:height - 1)
                    endif
                    break
                endif
            endwhile
        endif
    endif
    return content
endfunction

function! s:insertWrapLines(arr, arrIndex, line, width)
    if strdisplaywidth(a:line) <= a:width
        call insert(a:arr, a:line, a:arrIndex)
        return 1
    endif
    let num = 0
    let arrIndex = a:arrIndex
    let l = 0
    let len = len(a:line)
    while l < len
        let r = a:width
        while 1
            let s = strcharpart(a:line, l, r)
            if strdisplaywidth(s) > a:width
                let r -= 1
                continue
            endif
            call insert(a:arr, s, arrIndex)
            let arrIndex += 1
            let l += r
            let num += 1
            break
        endwhile
    endwhile
    return num
endfunction

