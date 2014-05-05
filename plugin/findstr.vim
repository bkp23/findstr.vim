" File: findstr.vim
" Authors: Yegappan Lakshmanan, B. Perry
" Version: 0.2
" Last Modified: 5 May 2014

" Protect against double-loading and
" prevent loading if not running windows
if exists("loaded_findstr") || !has ("gui_win32")
    finish
endif
let loaded_findstr = 1


" Save current cpo to restore at end of script
let s:cpo_save = &cpo
set cpo&vim

" Open the search output window.  Set this variable to zero, to not open
" the search output window by default.  You can open it manually by using
" the :cwindow command.
if !exists("Findstr_OpenQuickfixWindow")
    let Findstr_OpenQuickfixWindow = 1
endif

" Default search file list
if !exists("Findstr_Default_Filelist")
    let Findstr_Default_Filelist = '*'
endif

" Default search options
if !exists("Findstr_Default_Options")
    let Findstr_Default_Options = ''
endif

" RunFindStr()
function! s:RunFindStr(cmd_name, cmd_opt, ...)
    if a:0 > 0 && (a:1 == "-?" || a:1 == "-h")
        echo 'Usage: ' . a:cmd_name . ' [<options>] [<search_pattern> ' .
                        \ "[<file_name(s)>]]"
        return
    endif

    let findstr_opt  = ''
    let pattern   = ''
    let filenames = ''

    " Parse the arguments
    " findstr command-line flags are specified using the "/flag" format.  The
    " next argument is assumed to be the pattern. The following arguments are
    " assumed to be file names or file patterns
    let argcnt = 1
    while argcnt <= a:0
        if a:{argcnt} =~ '^/'
            let findstr_opt = findstr_opt . " " . a:{argcnt}
        elseif pattern == ''
            let pattern = a:{argcnt}
        else
            let filenames= filenames . " " . a:{argcnt}
        endif
        let argcnt = argcnt + 1
    endwhile

    if findstr_opt == ''
        let findstr_opt = g:Findstr_Default_Options
    endif

    " Display line number for all the matching lines
    let findstr_opt = findstr_opt . ' /N ' . a:cmd_opt

    " Get the identifier and file list from user
    if pattern == '' 
        if a:cmd_name == 'Findstring' || a:cmd_name == 'Rfindstring'
            let prompt = 'Search for text: '
        else
            let prompt = 'Search for pattern: '
        endif
        let pattern = input(prompt, expand("<cword>"))
        if pattern == ''
            return
        endif
    endif

    if a:cmd_name == 'Rfindstring' || a:cmd_name == 'Rfindpattern'
        let startdir = input('Start searching from directory: ', getcwd())
        if startdir == ''
            return
        endif
        " Remove trailing backslash, if present
        let startdir = substitute(startdir, '\\$', '', '')
        let findstr_opt = findstr_opt . ' /D:' . startdir
    endif

    if filenames == ''
        let filenames = input("Search in files: ", g:Findstr_Default_Filelist)
        if filenames == ''
            return
        endif
    endif

    echo "\n"

    let cmd = "findstr " . findstr_opt
    let cmd = cmd . ' /C:"' . pattern . '"'
    let cmd = cmd . ' ' . filenames

    let cmd_output = system(cmd)

    if cmd_output == ''
        echohl WarningMsg | 
        \ echomsg "Error: Pattern " . pattern . " not found" | 
        \ echohl None
        return
    endif

    " The file names in the recursive search output are relative to the start
    " directory. Need to convert them to absolute path.
    if a:cmd_name == 'Rfindstring' || a:cmd_name == 'Rfindpattern'
        let spat = "[^\n]\\+\n"
        let rpat = escape(startdir, '\') . '\\&'
        let cmd_output = substitute(cmd_output, spat, rpat, "g")
    endif

    let tmpfile = tempname()

    let old_verbose = &verbose
    set verbose&vim

    exe "redir! > " . tmpfile
    silent echon '[Search results for pattern: ' . pattern . "]\n"
    silent echon cmd_output
    redir END

    let &verbose = old_verbose

    let old_efm = &efm    " save off efm
    set efm=%f:%\\s%#%l:%m

    if exists(":cgetfile")
        execute "silent! cgetfile " . tmpfile
    else
        execute "silent! cfile " . tmpfile
    endif

    let &efm = old_efm   " restore efm

    " Open the search output window
    if g:Findstr_OpenQuickfixWindow == 1
        " Open the quickfix window below the current window
        botright copen
    endif

    call delete(tmpfile)
endfunction

" Define the findstr commands if running windows
if has ("gui_win32")
  fun Test()
    echo "Testing!!"
  endfunction
  command! -nargs=* -complete=file Findstring
              \ call s:RunFindStr("Findstring", "/L", <f-args>)
  command! -nargs=* -complete=file Findpattern
              \ call s:RunFindStr("Findpattern", "/R", <f-args>)
  command! -nargs=* -complete=file Rfindstring
              \ call s:RunFindStr("Rfindstring", "/S /L", <f-args>)
  command! -nargs=* -complete=file Rfindpattern
              \ call s:RunFindStr("Rfindpattern", "/S /R", <f-args>)
endif

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
