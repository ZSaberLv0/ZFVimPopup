
" {
"   'pos' : 'left/top/right/bottom/cursor,
"            can combine as `left|top` or `top|left` or `cursor|right|bottom`,
"            default is `right|bottom`',
"   'width' : '[1, ~) for fixed size,
"              or (0.0, 1.0) for percentage of window,
"              or function() to return a number or float value,
"              otherwise (not exists, zero, negative) use default,
"              default is 0',
"   'height' : 'default is 0',
"   'x' : 'offset according to pos,
"          or function() to return a number value,
"          default is 0',
"   'y' : 'default is 0',
"   'wrap' : 'default is 1',
"   'contentAlign' : 'top/bottom, default is `top`',
"   'contentOffset' : 'offset according to contentAlign,
"                      when contentAlign==top, >0 means scroll up,
"                      default is `0`',
" }
if !exists('g:ZFPopupDefaultConfig')
    let g:ZFPopupDefaultConfig = {}
endif
if !exists('g:ZFPopupDefaultWidth')
    let g:ZFPopupDefaultWidth = 1.0/4
endif
if !exists('g:ZFPopupDefaultHeight')
    let g:ZFPopupDefaultHeight = 5
endif

" {
"   'create' : 'function(popupid, config, frame) that return implState, the implState must contain `bufnr`',
"   'close' : 'function(popupid, config, implState)',
"   'show' : 'function(popupid, config, implState)',
"   'hide' : 'function(popupid, config, implState)',
"   'content' : 'function(popupid, config, implState, content, contentOrig), change content',
"   'config' : 'function(popupid, config, implState, config, frame), change config',
" }
if !exists('g:ZFPopupImpl')
    let g:ZFPopupImpl = {}
endif

function! ZFPopupAvailable()
    if !exists('s:available')
        let s:available = has('timers')
                    \ && !empty(get(g:ZFPopupImpl, 'create', ''))
                    \ && !empty(get(g:ZFPopupImpl, 'close', ''))
                    \ && !empty(get(g:ZFPopupImpl, 'show', ''))
                    \ && !empty(get(g:ZFPopupImpl, 'hide', ''))
                    \ && !empty(get(g:ZFPopupImpl, 'content', ''))
                    \ && !empty(get(g:ZFPopupImpl, 'config', ''))
    endif
    return s:available
endfunction

function! ZFPopupCreate(...)
    let config = extend(extend({
                \   'pos' : 'right|bottom',
                \   'width' : 0,
                \   'height' : 0,
                \   'x' : 0,
                \   'y' : 0,
                \   'wrap' : 1,
                \   'contentAlign' : 'top',
                \   'contentOffset' : 0,
                \ }, g:ZFPopupDefaultConfig), get(a:, 1, {}))
    let popupid = s:popupidNext()
    let frame = ZFPopupCalcFrame(config)
    let implState = g:ZFPopupImpl['create'](popupid, config, frame)
    if empty(implState) || !exists("implState['bufnr']")
        return -1
    endif
    let s:state[popupid] = {
                \   'config' : config,
                \   'content' : [],
                \   'show' : 1,
                \   'frame' : frame,
                \   'implState' : implState,
                \   'redrawTaskId' : -1,
                \ }
    call s:cursorEventCheckSetup()
    return popupid
endfunction

function! ZFPopupClose(popupid)
    if !exists('s:state[a:popupid]')
        return 0
    endif
    let state = s:state[a:popupid]
    unlet s:state[a:popupid]
    call g:ZFPopupImpl['close'](a:popupid, state['config'], state['implState'])
    call s:cursorEventCheckSetup()
    if state['redrawTaskId'] != -1
        call timer_stop(state['redrawTaskId'])
        let state['redrawTaskId'] = -1
    endif
endfunction

function! ZFPopupShow(popupid)
    if !exists('s:state[a:popupid]')
        return 0
    endif
    let state = s:state[a:popupid]
    call g:ZFPopupImpl['show'](a:popupid, state['config'], state['implState'])
    let state['show'] = 1
    call s:cursorEventCheckSetup()
endfunction

function! ZFPopupHide(popupid)
    if !exists('s:state[a:popupid]')
        return 0
    endif
    let state = s:state[a:popupid]
    call g:ZFPopupImpl['hide'](a:popupid, state['config'], state['implState'])
    let state['show'] = 0
    call s:cursorEventCheckSetup()
endfunction

function! ZFPopupContent(popupid, ...)
    if !exists('s:state[a:popupid]')
        return []
    endif
    let state = s:state[a:popupid]
    if a:0 == 0
        return state['content']
    endif
    let state['content'] = a:1
    if state['redrawTaskId'] == -1
        let state['redrawTaskId'] = timer_start(get(g:, 'ZFPopupRedrawDelay', 200), function('s:redrawCallback', [a:popupid]))
    endif
endfunction
function! s:redrawCallback(popupid, ...)
    if !exists('s:state[a:popupid]')
        return
    endif
    let state = s:state[a:popupid]
    let state['redrawTaskId'] = -1
    call g:ZFPopupImpl['content'](
                \ a:popupid,
                \ state['config'],
                \ state['implState'],
                \ ZF_PopupContentFix(a:popupid, state),
                \ state['content'])
endfunction

function! ZFPopupConfig(popupid, ...)
    if !exists('s:state[a:popupid]')
        return {}
    endif
    let state = s:state[a:popupid]
    if a:0 == 0
        return state['config']
    endif
    let state['config'] = a:1
    call g:ZFPopupImpl['config'](a:popupid, state['config'], state['implState'], state['frame'])
    call s:cursorEventCheckSetup()
endfunction

function! ZFPopupUpdate(popupid)
    if !exists('s:state[a:popupid]')
        return {}
    endif
    let state = s:state[a:popupid]
    let state['frame'] = ZFPopupCalcFrame(state['config'])
    call ZFPopupConfig(a:popupid, state['config'])
endfunction

function! ZFPopupUpdateAll()
    for popupid in keys(s:state)
        call ZFPopupUpdate(popupid)
    endfor
endfunction

function! ZFPopupFrame(popupid)
    if !exists('s:state[a:popupid]')
        return {}
    endif
    return s:state[a:popupid]['frame']
endfunction

function! ZFPopupBufnr(popupid)
    if !exists('s:state[a:popupid]')
        return -1
    else
        return s:state[a:popupid]['implState']['bufnr']
    endif
endfunction

function! ZFPopupState(popupid)
    if !exists('s:state[a:popupid]')
        return {}
    else
        return s:state[a:popupid]
    endif
endfunction

function! ZFPopupList()
    return keys(s:state)
endfunction

" {
"   'popupid' : {
"     'config' : {},
"     'content' : [],
"     'show' : 0,
"     'frame' : { // fixed calculated frame
"       'x' : '',
"       'y' : '',
"       'width' : '',
"       'height' : '',
"     },
"     'implState' : {
"       'bufnr' : '',
"     },
"     'redrawTaskId' : -1,
"   },
" }
if !exists('s:state')
    let s:state = {}
endif
if !exists('s:popupid')
    let s:popupid = 0
endif
function! s:popupidNext()
    while 1
        let s:popupid += 1
        if s:popupid >= 0 && !exists('s:state[s:popupid]')
            break
        endif
    endwhile
    return s:popupid
endfunction

function! s:getConfigValue(config, key)
    if type(a:config[a:key]) == type(function('function'))
        let Fn = a:config[a:key]
        return Fn()
    else
        return a:config[a:key]
    endif
endfunction
" {
"   'x' : '',
"   'y' : '',
"   'width' : '',
"   'height' : '',
" }
function! ZFPopupCalcFrame(config, ...)
    let ret = {
                \   'width' : s:getConfigValue(a:config, 'width'),
                \   'height' : s:getConfigValue(a:config, 'height'),
                \   'x' : s:getConfigValue(a:config, 'x'),
                \   'y' : s:getConfigValue(a:config, 'y'),
                \ }
    let screenWidth = &columns
    let screenHeight = &lines

    if ret['width'] > 0
        " nothing to do
    elseif g:ZFPopupDefaultWidth > 0
        let ret['width'] = g:ZFPopupDefaultWidth
    else
        let ret['width'] = 1.0/4
    endif
    if ret['width'] < 1
        let ret['width'] = float2nr(round(screenWidth * ret['width']))
    endif

    if ret['height'] > 0
        " nothing to do
    elseif g:ZFPopupDefaultHeight > 0
        let ret['height'] = g:ZFPopupDefaultHeight
    else
        let ret['height'] = 5
    endif
    if ret['height'] < 1
        let ret['height'] = float2nr(round(screenHeight * ret['height']))
    endif

    if stridx(a:config['pos'], 'cursor') >= 0
        if a:0 > 0
            let cursor = a:1
            let cursorX = cursor[0]
            let cursorY = cursor[1]
        else
            let cursor = getcurpos()
            let screenpos = screenpos(winnr(), cursor[1], cursor[2])
            let cursorX = screenpos['col']
            let cursorY = screenpos['row']
        endif
        if stridx(a:config['pos'], 'left') >= 0
            let ret['x'] = cursorX - ret['width'] - ret['x']
        elseif stridx(a:config['pos'], 'right') >= 0
            let ret['x'] = cursorX + 1 + ret['x']
        else
            let ret['x'] = cursorX - ret['width'] / 2 + ret['x']
        endif
        if stridx(a:config['pos'], 'top') >= 0
            let ret['y'] = cursorY - ret['height'] - ret['y']
        elseif stridx(a:config['pos'], 'bottom') >= 0
            let ret['y'] = cursorY + 1 + ret['y']
        else
            let ret['y'] = cursorY - ret['height'] / 2 + ret['y']
        endif
    else
        if stridx(a:config['pos'], 'left') >= 0
            let ret['x'] = 1 + ret['x']
        elseif stridx(a:config['pos'], 'right') >= 0
            let ret['x'] = screenWidth + 1 - ret['width'] - ret['x']
        else
            let ret['x'] = (screenWidth - ret['width']) /2 + ret['x']
        endif
        if stridx(a:config['pos'], 'top') >= 0
            let ret['y'] = 1 + ret['y']
        elseif stridx(a:config['pos'], 'bottom') >= 0
            let ret['y'] = screenHeight + 1 - ret['height'] - ret['y']
        else
            let ret['y'] = (screenHeight - ret['height']) / 2 + ret['y']
        endif
    endif

    if ret['x'] < 1
        let ret['x'] = 1
    elseif ret['x'] > screenWidth
        let ret['x'] = screenWidth
    endif
    if ret['y'] < 1
        let ret['y'] = 1
    elseif ret['y'] > screenHeight
        let ret['y'] = screenHeight
    endif

    if ret['x'] + ret['width'] >= screenWidth + 1
        let ret['width'] = screenWidth + 1 - ret['x']
    endif
    if ret['y'] + ret['height'] >= screenHeight + 1
        let ret['height'] = screenHeight + 1 - ret['y']
    endif

    return ret
endfunction

augroup ZFPopupUpdateByEditorResize_augroup
    autocmd!
    autocmd VimResized * call ZFPopupUpdateAll()
augroup END

function! s:cursorEventUpdate()
    for popupid in keys(s:state)
        if s:state[popupid]['show'] && stridx(get(s:state[popupid]['config'], 'pos', ''), 'cursor') >= 0
            call ZFPopupUpdate(popupid)
        endif
    endfor
endfunction
function! s:cursorEventCheckSetup()
    let exist = 0
    for state in values(s:state)
        if state['show'] && stridx(get(state['config'], 'pos', ''), 'cursor') >= 0
            let exist = 1
            break
        endif
    endfor
    if exist
        augroup ZFPopupUpdateByCursorMove_augroup
            autocmd!
            autocmd CursorMoved * call s:cursorEventUpdate()
        augroup END
    else
        augroup ZFPopupUpdateByCursorMove_augroup
            autocmd!
        augroup END
    endif
endfunction

