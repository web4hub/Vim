" Vim syntax file
" Language: Clang module map
" Maintainer: Saleem Abdulrasool <compnerd@compnerd.org>

" Prolog
if exists("b:current_syntax")
  finish
endif
if !exists('main_syntax')
  let main_syntax = 'modulemap'
endif

" ---------------------------------------------------------------------------
" Module declarations
" ---------------------------------------------------------------------------

" module-declaration:
"   explicit? framework? module module-id attributes? '{' ... '}'
"   extern module module-id string-literal
syntax keyword moduleKeyword nextgroup=moduleName,moduleWildcard skipwhite
    \ module

" Modifiers for module declarations.
syntax keyword moduleKeyword
    \ explicit
    \ framework

" "extern module Foo "foo.modulemap"" has a module keyword after extern.
syntax keyword moduleKeyword nextgroup=moduleKeyword,moduleName skipwhite
    \ extern

" Module identifier (alphanumeric plus underscore) and module name
" (one or more dot-separated identifiers).
syntax match moduleIdentifier contained
    \ /\<[A-Za-z_][A-Za-z_0-9]*\>/
syntax match moduleName contains=moduleIdentifier
    \ /\<\%([A-Za-z_][A-Za-z_0-9]*\.\)*[A-Za-z_][A-Za-z_0-9]*\>/

" ---------------------------------------------------------------------------
" Module members
" ---------------------------------------------------------------------------

" Header declarations. Keep modifiers separate so constructs such as
" "private textual header "Foo.h"" remain structurally highlighted.
syntax keyword moduleHeaderKeyword nextgroup=moduleString skipwhite
    \ header
syntax keyword moduleHeaderModifier nextgroup=moduleHeaderKeyword skipwhite
    \ exclude
    \ private
    \ textual

" "umbrella header "Foo.h"" and "umbrella "directory"" are both valid.
syntax keyword moduleHeaderModifier nextgroup=moduleHeaderKeyword,moduleString skipwhite
    \ umbrella

" link "Library" and other string-valued member declarations.
syntax keyword moduleKeyword nextgroup=moduleString skipwhite
    \ link

" Members specifying module names.
syntax keyword moduleKeyword nextgroup=moduleName skipwhite
    \ conflict
    \ export_as
    \ use

" Export declaration and wildcard-module-id.
" This also covers the inferred submodule form:
"   module * { export * }
syntax keyword moduleKeyword nextgroup=moduleName,moduleWildcard skipwhite
    \ export
syntax match moduleWildcard contains=moduleIdentifier
    \ /\*\|\<\%([A-Za-z_][A-Za-z_0-9]*\.\)\+\*/

" ---------------------------------------------------------------------------
" Feature requirements
" ---------------------------------------------------------------------------

" requires !?feature (',' !?feature)*
syntax keyword moduleKeyword nextgroup=moduleFeature,moduleFeatureNot skipwhite
    \ requires
syntax match moduleFeatureNot
    \ /!/
syntax keyword moduleFeature
    \ altivec blocks coroutines
    \ cplusplus cplusplus11 cplusplus14 cplusplus17 cplusplus20 cplusplus23
    \ c99 c11 c17 c23
    \ freestanding gnuinlineasm objc objc_arc opencl tls
    \ sse4 neon avx
    \ freebsd win32 windows linux ios macos watchos tvos iossimulator
    \ gnu gnueabi android msvc

" ---------------------------------------------------------------------------
" Attributes and config_macros
" ---------------------------------------------------------------------------

" Module/header attributes:
"   [system]
"   [extern_c]
"   [no_undeclared_includes]
"   [exhaustive]
syntax region moduleAttributes start=/\[/ skip=/,/ end=/\]/ contains=moduleAttribute
syntax keyword moduleAttribute contained
    \ system
    \ extern_c
    \ no_undeclared_includes
    \ exhaustive

" config_macros [attributes]? identifier (',' identifier)*
syntax keyword moduleKeyword nextgroup=moduleAttributes,moduleMacroName skipwhite
    \ config_macros
syntax match moduleMacroName contained nextgroup=moduleMacroSeparator skipwhite
    \ /\<[A-Za-z_][A-Za-z_0-9]*\>/
syntax match moduleMacroSeparator contained nextgroup=moduleMacroName skipwhite
    \ /,/

" ---------------------------------------------------------------------------
" Header attributes
" ---------------------------------------------------------------------------

" header-attrs: '{' (size integer-literal | mtime integer-literal)* '}'
syntax region moduleHeaderAttributes start=/{/ end=/}/ contains=moduleHeaderAttribute,moduleNumber
syntax keyword moduleHeaderAttribute contained nextgroup=moduleNumber skipwhite
    \ size
    \ mtime
syntax match moduleNumber contained
    \ /\<\d\+\>/

" ---------------------------------------------------------------------------
" Strings and comments
" ---------------------------------------------------------------------------

syntax region moduleString start=/"/ skip=/\\"/ end=/"/

syntax keyword moduleTodo HACK FIXME TODO contained
syntax region moduleComment start="/\*" end="\*/"
    \ contains=moduleComment,moduleLineComment,moduleTodo
syntax region moduleLineComment start="//" end="$"
    \ contains=moduleTodo

" ---------------------------------------------------------------------------
" Highlighting
" ---------------------------------------------------------------------------

highlight default link moduleComment Comment
highlight default link moduleLineComment Comment
highlight default link moduleIdentifier Identifier
highlight default link moduleName Typedef
highlight default link moduleKeyword Statement
highlight default link moduleHeaderKeyword Keyword
highlight default link moduleHeaderModifier PreProc
highlight default link moduleString String
highlight default link moduleTodo Todo
highlight default link moduleFeature Structure
highlight default link moduleFeatureNot Operator
highlight default link moduleAttributes Delimiter
highlight default link moduleAttribute PreProc
highlight default link moduleWildcard Character
highlight default link moduleMacroName Macro
highlight default link moduleMacroSeparator Delimiter
highlight default link moduleHeaderAttributes Delimiter
highlight default link moduleHeaderAttribute Keyword
highlight default link moduleNumber Number

" Epilog
let b:current_syntax = 'modulemap'
if main_syntax ==# 'modulemap'
  unlet main_syntax
endif
