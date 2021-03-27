if exists('g:loaded_vimwiki_lua')
  finish
endif

command! VimwikiIndex lua require'vimwiki'.index()
command! VimwikiDiaryIndex lua require'vimwiki'.diary()
command! VimwikiMakeDiaryNote lua require'vimwiki'.diary('today')
command! VimwikiMakeYesterdayDiaryNote lua require'vimwiki'.diary('yesterday')
command! VimwikiMakeTomorrowDiaryNote lua require'vimwiki'.diary('tomorrow')
command! VimwikiGenerateDiaryIndex lua require'vimwiki'.generate_index('diary')

let g:loaded_vimwiki_lua = 1
