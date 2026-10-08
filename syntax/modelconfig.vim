" Vim syntax file
" Language: AI/ML model configuration
" Maintainer: web4hub
"
" Designed for model-specific text manifests/configuration files using
" JSON/YAML/TOML-like key/value syntax. Binary model files such as GGUF,
" Safetensors, ONNX, and PyTorch checkpoints should keep their binary
" handling rather than being treated as source text.

if exists("b:current_syntax")
  finish
endif

if !exists('main_syntax')
  let main_syntax = 'modelconfig'
endif

" ---------------------------------------------------------------------------
" Comments
" ---------------------------------------------------------------------------

syntax keyword modelConfigTodo TODO FIXME HACK NOTE contained
syntax match modelConfigComment /#.*/ contains=modelConfigTodo
syntax match modelConfigComment /\/\/.*$/ contains=modelConfigTodo
syntax region modelConfigBlockComment start=/\/\*/ end=/\*\// contains=modelConfigTodo

" ---------------------------------------------------------------------------
" Structural punctuation
" ---------------------------------------------------------------------------

syntax match modelConfigDelimiter /[{}\[\],:]/
syntax match modelConfigAssignment /[=:]/

" ---------------------------------------------------------------------------
" Strings and scalar values
" ---------------------------------------------------------------------------

syntax region modelConfigString start=/"/ skip=/\\\|\\"/ end=/"/ contains=modelConfigEscape
syntax region modelConfigString start=/'/ skip=/\\\|\\'/ end=/'/ contains=modelConfigEscape
syntax match modelConfigEscape /\\[\\\/"'bfnrtu]/
syntax match modelConfigNumber /\<\%(-\=\d\+\%([.]\d\+\)\=\%([eE][+-]\=\d\+\)\=\)\>/
syntax keyword modelConfigBoolean true false
syntax keyword modelConfigNull null None
syntax match modelConfigVersion /\<v\=\d\+\.\d\+\%([.]\d\+\)\=\%([+-][A-Za-z0-9._-]\+\)\=\>/

" ---------------------------------------------------------------------------
" Model architecture keys
" ---------------------------------------------------------------------------

syntax keyword modelConfigArchitecture
    \ architectures architecture model_type model_name model_family
    \ model_type_alias torch_dtype dtype quantization quantization_config
    \ vocab_size hidden_size intermediate_size
    \ num_hidden_layers num_layers n_layer
    \ num_attention_heads num_key_value_heads num_kv_heads
    \ head_dim attention_head_dim
    \ max_position_embeddings max_seq_len max_sequence_length
    \ sliding_window use_sliding_window
    \ tie_word_embeddings
    \ initializer_range rms_norm_eps layer_norm_eps
    \ hidden_act activation
    \ bos_token_id eos_token_id pad_token_id unk_token_id

" ---------------------------------------------------------------------------
" Rotary / positional encoding
" ---------------------------------------------------------------------------

syntax keyword modelConfigRoPE
    \ rope_theta rope_scaling rope_type
    \ factor original_max_position_embeddings
    \ beta_fast beta_slow mscale mscale_all_dim
    \ partial_rotary_factor rotary_pct

" ---------------------------------------------------------------------------
" Transformer / attention
" ---------------------------------------------------------------------------

syntax keyword modelConfigAttention
    \ attention_bias attention_dropout hidden_dropout_prob
    \ q_proj k_proj v_proj o_proj
    \ qkv_proj qk_norm qk_norm_type
    \ use_cache pretraining_tp
    \ _attn_implementation attn_implementation
    \ flash_attn flash_attention sdpa

" ---------------------------------------------------------------------------
" Mixture-of-Experts
" ---------------------------------------------------------------------------

syntax keyword modelConfigMoE
    \ num_experts num_local_experts num_experts_per_tok
    \ num_selected_experts experts_per_token top_k
    \ moe_intermediate_size shared_expert_intermediate_size
    \ router_aux_loss_coef router_z_loss_coef
    \ router_jitter_noise
    \ norm_topk_prob
    \ shared_expert

" ---------------------------------------------------------------------------
" Vision / multimodal
" ---------------------------------------------------------------------------

syntax keyword modelConfigVision
    \ vision_config vision_model image_size image_sizes
    \ patch_size temporal_patch_size tubelet_size
    \ num_channels num_frames
    \ spatial_merge_size spatial_patch_size
    \ video_token_id image_token_id vision_start_token_id vision_end_token_id
    \ mm_projector mm_hidden_size projector_type
    \ audio_config audio_model sample_rate
    \ text_config

" ---------------------------------------------------------------------------
" Tokenizer / generation
" ---------------------------------------------------------------------------

syntax keyword modelConfigGeneration
    \ tokenizer_class tokenizer_name tokenizer_model_max_length
    \ chat_template
    \ generation_config
    \ max_new_tokens max_length min_length
    \ do_sample temperature top_p top_k
    \ typical_p repetition_penalty
    \ no_repeat_ngram_size
    \ num_beams num_return_sequences
    \ pad_token_id bos_token_id eos_token_id

" ---------------------------------------------------------------------------
" Runtime / serving / quantization metadata
" ---------------------------------------------------------------------------

syntax keyword modelConfigRuntime
    \ device device_map offload_folder
    \ quantization_method bits bitwidth group_size
    \ block_size sym symmetric
    \ compute_dtype storage_dtype
    \ backend backend_name runtime
    \ tensor_parallel_size pipeline_parallel_size
    \ context_length batch_size max_batch_size
    \ gguf_file safetensors_file checkpoint_path
    \ transformers_version torch_version
    \ library license

" ---------------------------------------------------------------------------
" Generic identifiers and enum-like values
" ---------------------------------------------------------------------------

syntax match modelConfigKey /\<[A-Za-z_][A-Za-z0-9_.-]*\>/
syntax match modelConfigPath /\<[A-Za-z0-9_./~-]\+\.[A-Za-z0-9._-]\+\>/

" ---------------------------------------------------------------------------
" Highlighting
" ---------------------------------------------------------------------------

highlight default link modelConfigComment Comment
highlight default link modelConfigBlockComment Comment
highlight default link modelConfigTodo Todo
highlight default link modelConfigDelimiter Delimiter
highlight default link modelConfigAssignment Operator
highlight default link modelConfigString String
highlight default link modelConfigEscape SpecialChar
highlight default link modelConfigNumber Number
highlight default link modelConfigBoolean Boolean
highlight default link modelConfigNull Constant
highlight default link modelConfigVersion Special
highlight default link modelConfigArchitecture Type
highlight default link modelConfigRoPE Special
highlight default link modelConfigAttention Keyword
highlight default link modelConfigMoE Function
highlight default link modelConfigVision Identifier
highlight default link modelConfigGeneration Statement
highlight default link modelConfigRuntime PreProc
highlight default link modelConfigKey Identifier
highlight default link modelConfigPath String

let b:current_syntax = 'modelconfig'
if main_syntax ==# 'modelconfig'
  unlet main_syntax
endif
