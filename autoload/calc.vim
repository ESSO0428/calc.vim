" Preview the arithmetic expression, with smart integer coercion
"
" Examples
" Let '|' be the cursor
"
" Integer result:
" 2 + 2|
" [4]
"
" Smart coercion:
" sqrt(4)|
" [2]
"
" Decimal result:
" sqrt(2)|
" [1.414214]
"
" Invalid expression:
" 2 + |
" []
function! calc#preview() abort

  try
    " Evaluate the expression
    let line = getline(line("$") - 1)
    let line = substitute(line, '\([A-Za-z0-9(), ]*\)^\([A-Za-z0-9(), ]*\)', 'pow(\1, \2)', "g")
    let result = eval(line)

    " Coerce to integer if possible
    let int_result = float2nr(result)
    let result = string(int_result == result ? int_result : result)
  catch

    " Invalid expression, make the preview blank
    let result = ""
  finally

    " Show the result of the expression
    silent! call setline("$", "[" . result . "]")

    " Update the current expression in the history
    if b:calc_history_changing
      let b:calc_history_changing = 0
    else
      let b:calc_history[-1] = getline(line("$") - 1)
    endif

  endtry

  return 1
endfunction

" Evaluate the current expression
" Let '|' be the cursor
"
" Turn this:
"
" 2 + sqrt(4)|
" [4]
"
" Into this:
"
" 2 + sqrt(4) = 4
" |
" []
function! calc#eval() abort

  " Get the result
  let line = getline("$")
  let line = strpart(line, 1, strlen(line) - 2)

  " The expression is invalid, it can't be evaluated
  if line == ""
    return 0
  endif

  let line_nr = line("$") - 1
  let line = getline(line_nr) . " = " . line

  " Add the expression to history and 'evaluate' the result
  silent! call add(b:calc_history, getline(line_nr))
  silent! call setline(line_nr, line)
  silent! call append(line_nr, "")

  " Update the history length
  let b:calc_history_pos = len(b:calc_history) - 1
  normal! j

  return 1
endfunction

" Go back and forth in history, behaves like history in the Unix shell (Maybe
" also windows shell, idk)
function! calc#history(direction) abort

  if a:direction == "p"

    " No more history
    if b:calc_history_pos < 1
      return 0
    endif

    " Go back in history
    let b:calc_history_pos -= 1
  else

    " No more history
    if b:calc_history_pos >= len(b:calc_history) - 1
      return 0
    endif

    " Go forward in history
    let b:calc_history_pos += 1
  endif

  " Update the text
  let b:calc_history_changing = 1
  silent! call setline(line("$") - 1, b:calc_history[b:calc_history_pos])

  normal! $
  return 1
endfunction

" Go back and forth in history, but instead of the expression this works on
" the values yielded from the expressions. If said expression is invalid and
" does not contain a value, then use the expression instead.
function! calc#val_history(direction)
  if calc#history(a:direction) == 1

    silent! call calc#preview()

    " Get the result
    let line = getline("$")
    let line = strpart(line, 1, strlen(line) - 2)

    " The expression is invalid, it can't be evaluated
    if line == ""
      return 0
    endif

    let b:calc_history_changing = 1
    silent! call setline(line("$") - 1, line)

    return 1
  endif

  return 0
endfunction

" Open the calculator
function! calc#open() abort

  " Open the calculator window
  10new
  setlocal buftype=nofile filetype=vim
  file Calculator

  " Keybindings
  inoremap <buffer> <silent> <C-c> <Esc>:bdelete!<CR>

  inoremap <buffer> <silent> <CR>  <C-o>:silent! call calc#eval()<CR>

  nnoremap <buffer> <silent> J     <C-o>:silent! call calc#history("n")<CR>
  nnoremap <buffer> <silent> K     <C-o>:silent! call calc#history("p")<CR>

  inoremap <buffer> <silent> <C-n> <C-o>:silent! call calc#history("n")<CR>
  inoremap <buffer> <silent> <C-p> <C-o>:silent! call calc#history("p")<CR>

  inoremap <buffer> <silent> <C-j> <C-o>:silent! call calc#history("n")<CR>
  inoremap <buffer> <silent> <C-k> <C-o>:silent! call calc#history("p")<CR>

  inoremap <buffer> <silent> <M-n> <C-o>:silent! call calc#val_history("n")<CR>
  inoremap <buffer> <silent> <M-p> <C-o>:silent! call calc#val_history("p")<CR>

  inoremap <buffer> <silent> <M-j> <C-o>:silent! call calc#val_history("n")<CR>
  inoremap <buffer> <silent> <M-k> <C-o>:silent! call calc#val_history("p")<CR>

  " History in the calculator
  let b:calc_history = [""]
  let b:calc_history_changing = 0
  let b:calc_history_pos = 0

  " Setup the ui
  autocmd TextChanged,TextChangedI <buffer> silent! call calc#preview()
  syntax match calcResult '^\[\S*\]$'
  silent! call append("$", "")

  " Ready. Set. Go!
  startinsert!

  return 1
endfunction
