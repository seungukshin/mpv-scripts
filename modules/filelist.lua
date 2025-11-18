--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local FileList = {
  name = 'FileList',
  version = '1.0',
  author = 'Seunguk Shin <seunguk.shin@gmail.com>',
  license = 'MIT - https://opensource.org/licenses/MIT',
}

--------------------------------------------------------------------------------
-- callback functions
--------------------------------------------------------------------------------

-- open items
-- items: the cursored directory
--     name: string for display
--     data: string for user data
-- return: none
function FileList:open(items)
  self.log:debug('open: start')

  -- single file
  if #items == 1 then
    local file = items[1].data
    -- go to parent
    if file == '..' then
      local path, name = self.utils.split_path(self.path)
      if mp.get_property('platform') == 'windows' then
	if path:sub(-2, -2) ~= ':' then
	  path = path:sub(1, -2)
	end
      else
	path = path:sub(1, -2)
      end
      self.path = path
      self:show(name)
      return
    end
    local path = self.utils.join_path(self.path, file)
    local info = self.utils.file_info(path)
    -- go to child
    if info.is_dir then
      self.path = path
      self:show(1)
      return
    end
    -- open file
    local ext = self.FileType:getExt(file)
    local type = self.FileType:getType(ext)
    if type == 'video' or type == 'music' then
      mp.commandv('loadfile', path, 'replace')
    elseif type == 'image' then
      mp.commandv('video-add', path, 'cursor')
    elseif type == 'subtitle' then
      mp.commandv('sub-add', path, 'cursor')
    end
    self.showlist:clear()
    return
  end
  -- multiple files
  local flag = 'replace'
  for _, v in pairs(items) do
    local file = v.data
    if file == '..' then goto continue end
    local path = self.utils.join_path(self.path, file)
    local info = self.utils.file_info(path)
    if info.is_dir then goto continue end
    mp.commandv('loadfile', path, flag)
    flag = 'append'
    self.showlist:clear()
    ::continue::
  end

  self.log:debug('open: end')
end

-- get file status
-- item: the cursored item
--       name: string for display
--       data: string for user data
-- return: file status string
function FileList:getStatus(item)
  self.log:debug('getStatus: start')

  local msg = ''
  if not item then
    return msg
  end
  local path = self.utils.join_path(self.path, item.data)
  local info = self.utils.file_info(path)
  local units = {'B', 'KB', 'MB', 'GB'}
  local unit = 1
  local size = info.size
  while size > 1024 do
    size = size / 1024
    unit = unit + 1
    if unit >= #units then break end
  end
  if info.is_dir then
    msg = 'type: directory'
  elseif info.is_file then
    local ext = self.FileType:getExt(item.data)
    local type = self.FileType:getType(ext)
    msg = string.format('type: %s, size: %.2f%s', type, size, units[unit])
  else
    msg = string.format('type: other, size: %.2f%s', size, units[unit])
  end

  self.log:debug('getStatus: end')

  return msg
end

--------------------------------------------------------------------------------
-- show
--------------------------------------------------------------------------------

-- show file list
-- cursor: the cursored index or name
-- return: none
function FileList:show(cursor)
  self.log:debug('show: start:', cursor)

  if not self.path then
    self.log:error('cannot find current path')
    return
  end

  local list = {}
  local dirs = self.utils.readdir(self.path, 'dirs');
  local files = self.utils.readdir(self.path, 'files');
  if mp.get_property('platform') == 'windows' then
    if self.path:sub(-2, -2) ~= ':' then
      table.insert(list, {
		     name = '  ..',
		     data = '..',
      })
    end
  else
    if self.path ~= '/' then
      table.insert(list, {
		     name = '  ..',
		     data = '..',
      })
    end
  end
  if dirs then
    for _, v in pairs(dirs) do
      table.insert(list, {
		     name = '  ' .. v,
		     data = v,
      })
    end
  end
  if files then
    for _, v in pairs(files) do
      local ext = self.FileType:getExt(v)
      table.insert(list, {
		     name = self.FileType:getIcon(ext) .. v,
		     data = v,
      })
    end
  end

  self.showlist:addKey('left', {
			 key = 'left',
			 func = function(item, cursor)
			   self:open({{ data = '..' }})
			 end,
			 opts = { repeatable = false },
  })
  self.showlist:addKey('right', {
			 key = 'right',
			 func = function()
			   local list = self.showlist:get()
			   self:open(list)
			 end,
			 opts = { repeatable = false },
  })
  self.showlist:addKey('enter', {
			 key = 'enter',
			 func = function()
			   local list = self.showlist:get()
			   self:open(list)
			 end,
			 opts = { repeatable = false },
  })

  local path = self.path
  if #path > 80 then
    local last = path:sub(-1, -1)
    if last == '/' or last == '\\' then
      path = path:sub(1, -2)
    end
    path = path:gsub('[^\\/]*[\\/]', '')
    path = self.utils.join_path('...', path)
  end
  self.showlist:clear()
  self.showlist:show('  ' .. path, list, function(item)
		       return self:getStatus(item)
  end, cursor)

  self.log:debug('show: end')
end

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

-- initialzie path
-- return: none
function FileList:init()
  self.log:debug('init: start')

  self.path = mp.get_property('path')
  if self.path then
    local info = self.utils.file_info(self.path)
    if not info.is_dir then
      self.path, _ = self.utils.split_path(self.path)
    end
  else
    self.path = self.utils.getcwd()
  end

  self.log:debug('init: end')
end

-- create new instance
-- return: new instance
function FileList:new()
  local path = mp.find_config_file('scripts')
  package.path = package.path .. ';' .. path .. '/?.lua'

  local Log = require('modules/log')
  local ShowList = require('modules/showlist')

  local _self = setmetatable({
      -- internal data
      utils = require('mp.utils'),
      FileType = require('modules/filetype'),
      log = Log:new('FileList'),
      showlist = ShowList:new(),
      path = nil,
  }, self)
  self.__index = self

  _self:init()

  return _self
end

return FileList
