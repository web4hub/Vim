" Vim syntax file
" Language: AI/ML model binary artifacts
" Maintainer: web4hub
"
" Binary model formats are intentionally not parsed as source code.
" This filetype provides a safe, explicit buffer classification for:
"   GGUF         - quantized/general model container
"   Safetensors  - tensor storage format
"   PyTorch PT   - PyTorch checkpoint/model artifact
"   ONNX         - Open Neural Network Exchange model
"
" Vim should not attempt syntax highlighting on these binary payloads.

if exists("b:current_syntax")
  finish
endif

if !exists('main_syntax')
  let main_syntax = 'modelbin'
endif

syntax keyword modelBinaryFormat
    \ GGUF
    \ SAFETENSORS
    \ PYTORCH
    \ ONNX

syntax keyword modelBinaryNote
    \ BinaryModelArtifact
    \ DoNotEditAsText

highlight default link modelBinaryFormat Type
highlight default link modelBinaryNote Comment

let b:current_syntax = 'modelbin'
if main_syntax ==# 'modelbin'
  unlet main_syntax
endif
