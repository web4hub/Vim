" Vim ftplugin for AI/ML model binary artifacts
" Language: GGUF / Safetensors / PyTorch PT / ONNX
"
" Binary model artifacts are not editable source text. Keep the buffer
" explicitly read-only and disable operations intended for text files.

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Set buffer encoding before disabling modifications.
setlocal binary
setlocal readonly
setlocal fileencoding=
setlocal nomodifiable
setlocal buftype=nowrite

let b:undo_ftplugin = "setlocal nobinary noreadonly modifiable buftype< fileencoding<"
