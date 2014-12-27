" vim-hykw-wp-mvc
" version: 1.3.0
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

if !exists('hykw_wp_mvc#ag_command')
  let g:hykw_wp_mvc#ag_command = "Ag "
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
function! Debug(str)
  ruby << EOL
    File.open('/tmp/zzz.txt', 'w') do |f|
      f.puts VIM.evaluate('a:str')
    end
EOL
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""
function! hykw_wp_mvc#tagjump()
  cd $PWD

  let msg_nf_method = 'Not Found: MVC method'
  let msg_nf_topdir = 'Not Found: MVC top directory'

  let cmds = hykw_wp_mvc#getCMDs()

  " get method name and path
  let line = getline('.')
  let work = hykw_wp_mvc#getMethod(line)
  if work['pos'] == -1
    call hykw_wp_mvc#search_caller(line)
    return ''
  endif
  let filePath = work['filePath']
  let fileName = work['fileName']

  " get the project files's top directory
  let topdir = hykw_wp_mvc#getTopDir()
  if topdir == ''
    echo msg_nf_topdir
    return msg_nf_topdir
  endif

  " get the args in the method
  let arg = matchlist(line, '\v\( *(.+) *\)')[1]
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

    call hykw_wp_mvc#openAndSearchString(openedFile, funcName)

  else
    let confirm = input('Fail to open(' . openedFile .'), Create?(y/N):'  )
    if confirm != 'y'
      return "\n"
    endif

    let dir = printf('%s/%s', topdir, filePath)
    if isdirectory(dir) != 1
      call mkdir(dir, 'p')
    endif

    if filereadable(openedFile) != 1
      if funcName == ''
        let buf = ['<?php', '', ]
      else
        let buf = ['<?php', '', 'function ' . funcName . '()', '{', '', '}'  ]
      endif

      call writefile(buf, openedFile)
      call hykw_wp_mvc#openAndSearchString(openedFile, funcName)
    endif

  endif

  return ''

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""
function! hykw_wp_mvc#search_caller(line)
  " filter?
  let filterNames = hykw_wp_mvc#getFilterName(a:line)
  if filterNames[0] > -1
    let searchString = printf('%s %s.*%s', g:hykw_wp_mvc#ag_command, filterNames[0], filterNames[1])
    execute searchString

    return
  else
    " at the line "function xxx()"?
    let pos = stridx(a:line, 'function')
    if pos > -1
      let funcName = matchlist(a:line, '\vfunction *([^(]+)')[1]
    else
      let funcName = ''
    endif
  endif

  let path = expand('%:p:h')
  let searchMethod = hykw_wp_mvc#getSearchMethod(path)
"  let fileName = hykw_wp_mvc#getMethodFileName(searchMethod)

  let searchString = printf('%s %s.*%s', g:hykw_wp_mvc#ag_command, searchMethod, funcName) . "[\\'" . '\\\"]'
  execute searchString
endfunction


" on apply_filters('view/sp2/aaaa')
"  return ['add_filter', 'view/sp2/aaaa']
"  return ['apply_filters', 'view/sp2/aaaa']
" not found, returns -1
function! hykw_wp_mvc#getFilterName(line)
  let pos = stridx(a:line, 'add_filter')
  if pos > -1
    let funcName = 'add_filter'
    let ret_func = 'apply_filters'
  else
    let pos = stridx(a:line, 'apply_filters')
    if pos > -1
      let funcName = 'apply_filters'
      let ret_func = 'add_filter'
    else
      return [-1]
    endif
  endif

  " it should be includes ' and/or "
  let ptn = printf('\v%s\( *([^,]+),.*\)', funcName)
  let filterName = matchlist(a:line, ptn)[1]

  return [ret_func, filterName]
endfunction



function! hykw_wp_mvc#getMethodFileName(searchMethod)
  let regexp = printf('\v%s/(.*)', hykw_wp_mvc#getCMDs()[a:searchMethod][0])
  echomsg regexp

  let filepath = matchlist(expand('%:r'), regexp)
"  echomsg string(filepath)
  return filepath[1]

endfunction


function! hykw_wp_mvc#getSearchMethod(path)
  let cmds = hykw_wp_mvc#getCMDs()
  let tmp_foundPath = ''

  let callMethodName = ''  "e.g.:callBehavior
  for method in keys(cmds)
    let searchPath = cmds[method][0]
    if stridx(a:path, searchPath) > -1
      "  model, model/behavior: model/behavior should be matched
      if len(tmp_foundPath) < len(searchPath)
        let tmp_foundPath = searchPath
        let callMethodName = method
      endif
    endif
  endfor

  return callMethodName
endfunction

function! hykw_wp_mvc#getCMDs()
  let cmds = {
        \  'callComponent': ['controller/component', ''],
        \  'callModel': ['model', 'index.php'],
        \  'callBehavior': ['model/behavior', ''],
        \  'callView': ['view', 'index.php'],
        \  'callHelper': ['view/helper', ''],
        \  'callUtil': ['util', ''],
        \  }
  return cmds
endfunction


function! hykw_wp_mvc#getMethod(line)
  let cmds = hykw_wp_mvc#getCMDs()
  for method in keys(cmds)
    let pos = stridx(a:line, method)

    " method found
    if pos != -1
      return {'pos': pos, 'filePath':cmds[method][0], 'fileName':cmds[method][1]}
    endif
  endfor

  return {'pos': pos}
endfunction


function! hykw_wp_mvc#openAndSearchString(openedFile, funcName)
  execute printf("split %s", a:openedFile)

  call cursor(1,1)
  call search(a:funcName)

  " move to the first character
  let window_pos = getpos('.')
  let window_pos[2] = 0
  call setpos('.', window_pos)
endfunction

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
