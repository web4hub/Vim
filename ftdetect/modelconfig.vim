" Vim filetype detection file
" Language: AI/ML model configuration and binary artifacts

if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  au BufNewFile,BufRead *.modelconfig,*.modelcfg setf modelconfig
  au BufNewFile,BufRead *.model.json setf modelconfig
  au BufNewFile,BufRead *.gguf,*.safetensors,*.pt,*.onnx setf modelbin
augroup END
