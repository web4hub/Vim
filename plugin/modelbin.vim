" Vim plugin for AI/ML model binary artifacts
" Language: GGUF / Safetensors / PyTorch PT / ONNX
"
" Provides safe inspection commands without decoding or editing binary payloads.
" Format-specific tensor/metadata parsing is intentionally delegated to
" dedicated model tooling rather than Vim's text engine.

if exists('g:loaded_modelbin')
  finish
endif
let g:loaded_modelbin = 1

function! s:model_format(path) abort
  let l:ext = tolower(fnamemodify(a:path, ':e'))
  return {
        \ 'gguf': 'GGUF',
        \ 'safetensors': 'Safetensors',
        \ 'pt': 'PyTorch checkpoint',
        \ 'onnx': 'ONNX'
        \ }->get(l:ext, 'AI/ML binary artifact')
endfunction

function! s:model_info() abort
  if empty(expand('%:p'))
    echoerr 'ModelInfo: buffer has no file name'
    return
  endif

  let l:path = expand('%:p')
  let l:size = getfsize(l:path)

  echo 'ModelInfo'
  echo '  Format: ' . s:model_format(l:path)
  echo '  File:   ' . l:path
  echo '  Size:   ' . (l:size < 0 ? 'unavailable' : l:size . ' bytes')
  echo '  Type:   ' . &filetype
  echo '  Edit:   ' . (&modifiable ? 'enabled' : 'disabled')
  echo '  Note:   binary payload; use format-specific tooling for metadata/tensors'
endfunction

command! ModelInfo call <SID>model_info()
command! ModelTensors echoerr 'ModelTensors: tensor inspection is not implemented yet; use a format-specific model inspector.'
command! ModelArchitecture echoerr 'ModelArchitecture: architecture inspection is not implemented yet; use modelconfig or format-specific metadata tooling.'
command! ModelQuantization echoerr 'ModelQuantization: quantization inspection is not implemented yet; use GGUF/model metadata tooling.'

augroup modelbin_commands
  autocmd!
  autocmd FileType modelbin command! -buffer ModelInfo call <SID>model_info()
augroup END
