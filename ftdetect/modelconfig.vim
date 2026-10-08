" Vim filetype detection file
" Language: AI/ML model configuration

if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  au BufNewFile,BufRead *.modelconfig,*.modelcfg setf modelconfig
  au BufNewFile,BufRead *.model.json setf modelconfig
augroup END
