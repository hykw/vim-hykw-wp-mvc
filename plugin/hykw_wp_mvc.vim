" vim-hykw-wp-mvc
" version: 1.0.1
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
let msg_nf_method = 'Not Found: MVC method'
let msg_nf_topdir = 'Not Found: MVC top directory'

  let cmds = {
        \  'callComponent': ['controller/component', ''],
        \  'callModel': ['model', 'index.php'],
        \  'callBehavior': ['model/behavior', ''],
        \  'callView': ['view', 'index.php'],
        \  'callHelper': ['view/helper', ''],
        \  }

  " get method name and path
  let line = getline('.')
  for method in keys(cmds)
    let pos = stridx(line, method)

    " method found
    if pos != -1
      let filePath = cmds[method][0]
      let fileName = cmds[method][1]
      break
    endif
  endfor

  if pos == -1
    echo msg_nf_method
    return msg_nf_method
  endif

  " get the project files's top directory
  let topdir = hykw_wp_mvc#getTopDir()
  if topdir == ''
    echo msg_nf_topdir
    return msg_nf_topdir
  endif

  " get the args in the method
  let arg = matchstr(line, '(.*)', pos)[1:-2]
  let arg = substitute(arg, "'", '', 'g')
  let args = hykw_wp_mvc#getArgs(arg)      " ["sp2/header", ""]


  " *****
  " callModel, callView: the 1st argument is directory name(index.php is in it), the 2nd one is
  " function name.
  "
  " callComponent, callBehavior, callHelper: the 1st one is filename(.php is omitted)

"     index.php
"        $objMVC->callModel('top', 'get_catline', $catname);
"        $objMVC->callView('top', 'view_top', $args);
"     others
"        $gobjMVC->callComponent('sp/archives', 'view_archivePages', $args);
"        $objMVC->callBehavior('urls', 'get_imgPath');
"        $objMVC->callHelper('footer');

  " methods: callComponent, callBehavior, callHelper?
  if (fileName == '')
    let fileName = args[0] . ".php"
  else " model/view
    let fileName = args[0] . "/index.php"
  endif
  let funcName = args[1]

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

  " find out the top dir if this file is there or not.
  let targetDir = 'controller'
  if glob(targetDir) != ''
    return $PWD
  endif

  lcd $PWD
  let path = globpath('*', 'controller')
  if path == ''
    return ''
  endif

  return $PWD . '/' . split(path, '/')[0]
endfunction


" get the first and second args in []
function! hykw_wp_mvc#getArgs(arg)
  let args = split(a:arg, ',')

  " function name is empty?
  if (len(args) == 1)
    return [args[0], '']
  else
    return [args[0], args[1]]
  endif
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = s:save_cpo
unlet s:save_cpo
