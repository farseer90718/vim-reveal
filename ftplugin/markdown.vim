if !exists('g:reveal_config')
  let g:reveal_config = {}
endif

if !exists('g:vim_reveal_loaded') || g:vim_reveal_loaded == 0
  let g:vim_reveal_loaded = 1

  let s:default_config = {
              \'controls': 'true',
              \'progress': 'true',
              \'history': 'false',
              \'keyboard': 'true',
              \'touch': 'true',
              \'center': 'true',
              \'loop': 'false',
              \'rtl': 'false',
              \'mouseWheel': 'false',
              \'margin': '0.1',
              \'minScale': '0.2',
              \'maxScale': '1.0',
              \'autoSlide': '0',
              \'width': '960',
              \'height': '900',
              \'theme': 'zenburn',
              \'transition': 'default',
              \'transitionSpeed': 'default',
              \'backgroundTransition': 'default',
              \'filename': 'reveal',
              \'title': 'title',
              \'author': 'author',
              \'path': $HOME.'/reveal.js/',
              \'description': 'This presentation is generated by vim-reveal and reveal.js.'}

  let s:root_path = has_key(g:reveal_config, 'path')
        \           ? g:reveal_config.path
        \           : s:default_config.path
  let s:root_path = fnamemodify(expand(s:root_path), ':p')

  let s:template_path = expand('<sfile>:p:h').'/../template/'
  let s:modes = {
    \ 'default': 0,
    \ 'new': 1,
    \ 'md': 2
    \ }

  func! s:GetFilename(config, global_config)
    let result = ''
    if !has_key(a:global_config, 'filename')
      let lower = substitute(a:config.title, '\u\+', '\L&', 'g')
      let with_dashes = substitute(lower, '\s\+', '-', 'g')
      let from_title = substitute(with_dashes, '[^a-z_.0-9-]\+', '', 'g')
      let result = len(from_title) > 0 ? from_title : a:config.filename
    else
      let result = a:global_config.filename
    endif
    return result
  endfunc

  function! s:Md2Reveal(...)
    if finddir(s:root_path) == ''
      throw 'FileNotExistentError: directory '.s:root_path.' does not exists'
    endif
    let s:output_path = s:root_path . 'presentations/'
    if finddir(s:output_path) == ''
      call mkdir(s:output_path)
    endif
    let open_mode = a:0 && has_key(s:modes, a:1) ? s:modes[a:1] : s:modes.default
    let md_file = expand('%:p')
    let cur_pos = getpos('.')
    let content = s:GetContent()
    let Metadata = s:GetMetadata(s:default_config, g:reveal_config)
    if open_mode == s:modes.new
      wincmd n
    endif
    let filename = s:GetFilename(Metadata, g:reveal_config)
    execute 'edit '.s:output_path . filename.'.html'
    normal ggdG
    execute '0read '.s:template_path.'head'
    let endofhead = line('$')
    execute '$read '.s:template_path.'tail'
    for [mkey, mvalue] in items(Metadata)
      silent! execute '%s/{%\s*'.mkey.'\s*%}/'.mvalue.'/g'
    endfor
    call append(endofhead, content)
    1
    write!
    if open_mode == s:modes.md
      execute 'edit '.md_file
      call setpos('.', cur_pos)
    endif
  endfunction

  function! s:GetContent()
    let content = []
    1
    while 1
      let line1 = search('^\s*<!--\s*sec.*-->\s*$', 'eW')
      let line2 = search('^\s*<!--\s*sec.*-->\s*$', 'nW')
      let secno1 = matchstr(getline(line1), 'secp\=\s*\zs\d\+')
      let secno2 = matchstr(getline(line2), 'secp\=\s*\zs\d\+')
      let subsecno = matchstr(getline(line1), 'secp\=\s*\d\+\.\zs\d\+')
      let sectype = matchstr(getline(line1), 'sec\zs.')
      let opt = matchstr(getline(line1), 'secp\=\s*[.0-9]*\s*\zs.*\ze-->')
      let opt = substitute(opt, 'bgtr=', 'data-background-transition=', 'g')
      let opt = substitute(opt, 'bgrp=', 'data-background-repeat=', 'g')
      let opt = substitute(opt, 'bgsz=', 'data-background-size=', 'g')
      let opt = substitute(opt, 'bg=', 'data-background=', 'g')
      let opt = substitute(opt, 'tr=', 'data-transition=', 'g')
      let endlineno = line2? line2-1: line('$')
      if line1
        let sechead = ['<section data-markdown '.opt.'>']
        let sectail = ['</section>']
        let subhead = ['<script type="text/template">']
        let subtail = ['</script>']
        if sectype == 'p'
          let sechead = ['<section '.opt.'>']
          let subhead = []
          let subtail = []
        endif
        if secno1 == secno2 && secno1 != ''
          if subsecno =~ '^1\=$'
            let sechead = ['<section>']+sechead
          endif
        elseif subsecno != ''
          let sectail = sectail+sectail
        endif
        let content += sechead+subhead+getline(line('.')+1, endlineno)+subtail+sectail
      endif
      if line2 == 0
        return content
      endif
    endwhile
  endfunction

  function! s:GetMetadata(default_config, global_config)
    let Metadata = {}
    let lineno = 1
    while getline(lineno) =~ '^\(<!--Meta\s\+.*-->\)\=$'
      execute lineno
      while search('[^ ]*\s*:', 'e', lineno)
        let key = matchstr(getline(lineno)[:getpos('.')[2]-1], '[^ ]*\ze\s*:$')
        let value = matchstr(getline(lineno)[getpos('.')[2]:], '^\s*\zs.\{-}\ze\(\s\+[^ ]*\s*:\|-->\)')
        if key != ''
          let Metadata[key] = value
        endif
      endwhile
      let lineno += 1
    endwhile
    let local_config = extend(copy(a:default_config), a:global_config)
    let Metadata = extend(Metadata, local_config, "keep")
    return Metadata
  endfunction

command!
      \ -nargs=?
      \ RevealIt
      \ call <sid>Md2Reveal(<q-args>)
endif
