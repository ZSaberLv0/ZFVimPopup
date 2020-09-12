
util to show popup for vim8 and neovim

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins


# Install

use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

```
Plugin 'ZSaberLv0/ZFVimPopup'
Plugin 'ZSaberLv0/ZFVimJob' " optional, recommeded to combine with this job utility
```

# Usage

```
let popupId = ZFPopupCreate({
        \   'pos' : 'cursor|right|bottom',
        \ })
call ZFPopupContent(popupId, ['line1', 'line2'])
call ZFPopupClose(popupId)
```

# Functions

* `ZFPopupCreate([config])`

    return popupId if success, or -1 if failed

    config: (default config can be configured by `g:ZFPopup_defaultConfig`)

    * `pos` : `left/right/top/bottom/cursor`,
        can combine as 'cursor|left|top',
        element order doesn't matter,
        default is `right|bottom`
    * `width` / `height`
        * `[1, 9999)` : use fixed size
        * `(0.0, 1.0)` : use size relative to screen size
        * others : use `1.0/4` and `5`
    * `x` / `y` : offset according to `pos`
    * `wrap` : `0` or `1`, whether `:h wrap` in popup window,
        default is `1`

* `ZFPopupClose(popupId)`
* `ZFPopupShow(popupId)`
* `ZFPopupHide(popupId)`
* `ZFPopupContent(popupId [, content])`
    * when `content` not specified, return current content (as List of strings)
    * when `content` specified, set the entire content of popup buffer
* `ZFPopupConfig(popupId [, config])`
    * when `config` not specified, return popup's config
    * when `config` specified, change and update popup's config
* `ZFPopupFrame(popupId)` : return popup's window frame, as `{'x':0,'y':0,'width':0,'height':0}`
* `ZFPopupBufnr(popupId)` : return popup's `bufnr()`
* `ZFPopupList()` : return a List of popupId

