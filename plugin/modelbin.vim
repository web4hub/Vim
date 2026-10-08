" Vim plugin for AI/ML model binary artifacts
" Language: GGUF / Safetensors / PyTorch PT / ONNX
"
" Provides safe, read-only inspection of model metadata and tensor indexes.
" PyTorch pickle payloads are never unpickled or executed.

if exists('g:loaded_modelbin')
  finish
endif
let g:loaded_modelbin = 1

function! s:model_script() abort
  return expand('<sfile>:p:h:h') . '/tools/model_inspect.py'
endfunction

function! s:inspect(kind) abort
  let l:path = expand('%:p')
  if empty(l:path)
    echoerr 'Model inspection: buffer has no file name'
    return
  endif
  let l:script = s:model_script()
  if !filereadable(l:script)
    echoerr 'Model inspection: tools/model_inspect.py is missing'
    return
  endif

  let l:cmd = 'python3 ' . shellescape(l:script) . ' ' .
         shellescape(a:kind) . ' ' . shellescape(l:path)
  let l:output = system(l:cmd)
  if v:shell_error
    echoerr substitute(l:output, '\n$', '', '')
    return
  endif

  try
    let l:data = json_decode(l:output)
  catch
    echoerr 'Model inspection: invalid JSON returned by inspector'
    return
  endtry

  if has_key(l:data, 'error')
    echoerr 'Model inspection: ' . l:data.error
    return
  endif

  new
  setlocal buftype=nofile bufhidden=wipe noswapfile
  setlocal filetype=json
  call setline(1, split(json_encode(l:data), '\zs'))
  setlocal nomodifiable
  setlocal readonly
  normal! gg
endfunction

function! s:model_info() abort
  let l:path = expand('%:p')
  if empty(l:path)
    echoerr 'ModelInfo: buffer has no file name'
    return
  endif
  echo 'ModelInfo'
  echo '  Format: ' . toupper(fnamemodify(l:path, ':e'))
  echo '  File:   ' . l:path
  echo '  Size:   ' . getfsize(l:path) . ' bytes'
  echo '  Type:   ' . &filetype
  echo '  Edit:   ' . (&modifiable ? 'enabled' : 'disabled')
  echo '  Use:    :ModelTensors / :ModelArchitecture / :ModelQuantization'
endfunction

command! ModelInfo call <SID>model_info()
command! ModelTensors call <SID>inspect('tensors')
command! ModelArchitecture call <SID>inspect('architecture')
command! ModelQuantization call <SID>inspect('quantization')

augroup modelbin_commands
  autocmd!
  autocmd FileType modelbin command! -buffer ModelInfo call <SID>model_info()
  autocmd FileType modelbin command! -buffer ModelTensors call <SID>inspect('tensors')
  autocmd FileType modelbin command! -buffer ModelArchitecture call <SID>inspect('architecture')
  autocmd FileType modelbin command! -buffer ModelQuantization call <SID>inspect('quantization')
augroup END
