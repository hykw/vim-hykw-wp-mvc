" vim-hykw-wp-mvc
" version: 1.0
" Author: Hitoshi Hayakawa
" License: MIT
"
" This is a Vim script for HYKW MVC Wordpress Plugin
"  c.f. https://github.com/hykw/hykw-wp-mvc

if exists('g:loaded_hykw_wp_mvc')
  finish
endif
let g:loaded_hykw_wp_mvc = 1

let s:save_cpo = &cpo
set cpo&vim

""""""""""""""""""""""""""""""""""""""""""""""""""
function! hykw_wp_mvc#tagjump()
  let cmds = {
        \  'callComponent': 'controller/component',
        \  'callModel': 'model',
        \  'callBehavior': 'model/behavior',
        \  'callView': 'view',
        \  'callHelper': 'view/helper'
        \  }

  " get method name and path
  let line = getline('.')
  for method in keys(cmds)
    let pos = stridx(line, method)

    if pos != -1
      let filePath = cmds[method]
      break
    endif
  endfor

  if pos == -1
    return ''
  endif

  " get the args in the method
  let arg = matchstr(line, '(.*)', pos)[1:-2]
  let arg = substitute(arg, "'", '', 'g')
  let args = hykw_wp_mvc#getArgs(arg)      " ["sp2/header", ""]
  let fileName = args[0] . ".php"
  let funcName = args[1]

  " get the project files's top directory
  let topdir = hykw_wp_mvc#getTopDir()
  if topdir == ''
    return ''
  endif

  let openedFile = printf('%s/%s/%s', topdir, filePath, fileName)
  if filereadable(openedFile)
    " the file is going to be opend in other window.
    if winnr('$') > 1
      only
    endif

    execute printf("split %s", openedFile)

    call cursor(1,1)
    call search(funcName)

    " move to the first character
    let window_pos = getpos('.')
    let window_pos[2] = 0
    call setpos('.', window_pos)
  endif

  return ''

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""
function! hykw_wp_mvc#getTopDir()
  " FIXME: it should read style.css, and check if in the parent themes' directory

  let path = globpath('*', 'controller')
  if path == ''
    return ''
  endif

  return $PWD . '/' . split(path, '/')[0]
endfunction


function! hykw_wp_mvc#getArgs(arg)
  let args = split(a:arg, ',')

  " function name is empty?
  if (len(args) == 1)
    return [args[0], '']
  else
    return args
  endif
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = s:save_cpo
unlet s:save_cpo
