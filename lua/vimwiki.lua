local settings = {
  ['path'] = '~/vimwiki/',
  ['syntax'] = 'markdown',
  ['index'] = 'README',
  ['ext'] = '.md',
  ['diary'] = {['path'] = 'diary/', ['index'] = 'diary'},
  ['notes'] = {['path'] = 'notes/', ['index'] = 'notes'},
  ['link_space_char'] = '_'
}

local fstack = {}

local function pushf(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end

  table.insert(fstack, path)
  vim.api.nvim_command('edit ' .. path)
end
local function popf()
  if #fstack ~= 1 then
    fstack[#fstack] = nil
    vim.api.nvim_command('edit ' .. fstack[#fstack])
  end
end

local function follow_link()
  local match = {}
  if settings.syntax == 'markdown' then
    local pos = vim.fn.getcurpos()
    local line = vim.fn.getline('.')
    local pattern = '%[[^%]]+%]%(([^%)]+)%)'
    repeat
      local start = string.find(line, pattern, 1)
      match = string.match(line, pattern, 1)
    until (match == nil or (pos[3] >= start and pos[3] <= start + match:len()))
  end
  if match ~= nil then
    if match[0] == '/' then
      pushf(settings.path .. match:sub(2))
    else
      pushf(vim.fn.expand("%:p:h") .. '/' .. match)
    end
    return true
  end
  return false
end

local function create_link(mode)
  local text = vim.fn.expand('<cword>')
  if mode == 'v' then
    local vbegin = vim.fn.getpos("'<")
    local vend = vim.fn.getpos("'>")
    local lines = vim.fn.getline(vbegin[2], vend[2])
    if lines[1] == nil then return end
    lines[1] = string.sub(lines[1], vbegin[3])
    lines[#lines] = string.sub(lines[#lines], 0, vend[3] - 1)
    text = table.concat(lines, '\n')
  end
  local line = vim.fn.getline('.')
  if settings.syntax == 'markdown' then
    line = string.gsub(line, text,
                       '[' .. text .. '](' ..
                           text:gsub(' ', settings.link_space_char) ..
                           settings.ext .. ')')
  end
  vim.fn.setline('.', line)
end

local function follow_or_create_link()
  if follow_link() == false then create_link() end
end

local function go_back_link() popf() end

function VIMWIKI_SETUP_HOOK()
  vim.api.nvim_buf_set_keymap(0, 'n', '<CR>',
                              [[:lua require'vimwiki'.follow_or_create_link('n')<CR>]],
                              {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(0, 'v', '<CR>',
                              [[:lua require'vimwiki'.create_link('v')<CR>]],
                              {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(0, 'n', '<BS>',
                              [[:lua require'vimwiki'.go_back_link()<CR>]],
                              {noremap = true, silent = true})
end

function VIMWIKI_GENERATE_INDEX() require('vimwiki').generate_index() end

local function generate_index()
  local dir = vim.fn.expand("%:p:h")
  local name = vim.fn.fnamemodify(dir, ":t")
  if name == vim.fn.expand("%:r") then return end
  local lines = {}
  local str_files = vim.fn.globpath(dir, "*" .. settings.ext)
  local files = vim.fn.split(str_files, '\n')
  table.sort(files, function(a, b) return a > b end)
  if files == nil then return end
  local year = "0000"
  local month = "00"
  local months = {
    ['01'] = 'January',
    ['02'] = 'Feburary',
    ['03'] = 'March',
    ['04'] = 'April',
    ['05'] = 'May',
    ['06'] = 'June',
    ['07'] = 'July',
    ['08'] = 'August',
    ['09'] = 'September',
    ['10'] = 'October',
    ['11'] = 'November',
    ['12'] = 'December'
  }

  for _, file in ipairs(files) do
    local fname = vim.fn.fnamemodify(file, ":t:r")
    if fname:find('%d%d%d%d%-%d%d%-%d%d') ~= nil then
      local fyear = fname:sub(1, 4)
      local fmonth = fname:sub(6, 7)
      if year ~= fyear then
        if year ~= "0000" then table.insert(lines, "") end
        table.insert(lines, "## " .. fyear)
        table.insert(lines, "")
        if year == "0000" then
          table.insert(lines, ":personal:")
          table.insert(lines, "")
        end
        table.insert(lines, "### " .. months[fmonth])
        table.insert(lines, "")
        year = fyear
        month = fmonth
      elseif month ~= fmonth then
        table.insert(lines, "")
        table.insert(lines, "### " .. months[fmonth])
        table.insert(lines, "")
        month = fmonth
      end
      table.insert(lines, "- [" .. fname .. "](" .. fname .. settings.ext .. ")")
    end
  end

  vim.fn.writefile(lines, dir .. "/" .. name .. settings.ext)
end

local function open_index()
  pushf(settings.path .. settings.index .. settings.ext)
end

local function open_diary(date)
  local path = settings.path .. settings.diary.path;
  if date == nil then
    path = path .. settings.diary.index .. settings.ext;
  elseif date == 'today' then
    path = path .. os.date('%Y-%m-%d') .. settings.ext;
  elseif date == 'yesterday' then
    path = path .. os.date('%Y-%m-%d', os.time() - 86400) .. settings.ext;
  elseif date == 'tomorrow' then
    path = path .. os.date('%Y-%m-%d', os.time() + 86400) .. settings.ext;
  else
    path = path .. date .. settings.ext;
  end
  pushf(path)
end

local function open_notes(date)
  local path = settings.path .. settings.notes.path;
  if date == nil then
    path = path .. settings.notes.index .. settings.ext;
  elseif date == 'today' then
    path = path .. os.date('%Y-%m-%d') .. settings.ext;
  elseif date == 'yesterday' then
    path = path .. os.date('%Y-%m-%d', os.time() - 86400) .. settings.ext;
  elseif date == 'tomorrow' then
    path = path .. os.date('%Y-%m-%d', os.time() + 86400) .. settings.ext;
  else
    path = path .. date .. settings.ext;
  end
  pushf(path)
end

local function setup(config)
  if config['path'] ~= nil then settings.path = config['path'] end
  if config['syntax'] ~= nil then settings.syntax = config['syntax'] end
  if config['index'] ~= nil then settings.index = config['index'] end
  if config['ext'] ~= nil then settings.ext = config['ext'] end
  if config['link_space_char'] ~= nil then
    settings.link_space_char = config['link_space_char']
  end

  vim.api.nvim_command('augroup VimwikiSetup')
  vim.api.nvim_command('autocmd! *')
  vim.api.nvim_command('autocmd BufEnter ' .. settings.path ..
                           '* lua VIMWIKI_SETUP_HOOK()')
  vim.api.nvim_command('autocmd BufWritePost ' .. settings.path ..
                           settings.diary.path ..
                           '* lua VIMWIKI_GENERATE_INDEX()')
  vim.api.nvim_command('autocmd BufWritePost ' .. settings.path ..
                           settings.notes.path ..
                           '* lua VIMWIKI_GENERATE_INDEX()')
  vim.api.nvim_command('augroup END')
end

return {
  setup = setup,
  index = open_index,
  diary = open_diary,
  note = open_note,
  generate_index = generate_index,
  create_link = create_link,
  go_back_link = go_back_link,
  follow_or_create_link = follow_or_create_link
}
