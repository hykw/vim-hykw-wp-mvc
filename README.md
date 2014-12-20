# vim-hykw-wp-mvc

This is a Vim script for HYKW MVC Wordpress Plugin(https://github.com/hykw/hykw-wp-mvc)

It works like Tags. When you call the function "hykw_wp_mvc#tagjump()" in the line below, it jump to the function defined:

    callComponent
    callModel
    callBehavior
    callView
    callHelper

e.g.

    1 <?php
    2 global $gobjMVC
    3 $gobj->callHelper('sp/ranking', 'view');
    4 //

    In the line 3, you call hykw_wp_mvc#tagjump(), it jumps.

Since 1.1.0, when you call the function in the definition(function view() in
view/help/sp/ranking.php), it grep the sources with the Ag command.

The default command which does grep is defined like below:
  let g:hykw_wp_mvc#ag_command = "Ag "

## Installation
You can install it with NeoBundle, like those.

## Configuration
I use tags with :tag, I call the function with the following key.

    nnoremap <C-]> :<C-u>call hykw_wp_mvc#tagjump()<CR>

## *** Notice ***
This is my first Vim script. I've started to change the editor from Emacs to Vim since Dec. 2014, there may be some problem in the script :-)

