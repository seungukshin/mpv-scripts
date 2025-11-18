--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local PlayList = {
  name = 'PlayList',
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
function PlayList:open(items)
  self.log:debug('open: start')

  mp.set_property('playlist-pos', tonumber(items[1].data));
  self.showlist:clear()

  self.log:debug('open: end')
end

-- get file status
-- item: the cursored item
--       name: string for display
--       data: string for user data
-- return: file status string
function PlayList:getStatus(item)
  self.log:debug('getStatus: start')

  local msg = ''
  if not item then return msg end
  local pi = self.list[tonumber(item.data)]
  if not pi then return msg end
  local path = pi.filename
  self.log:info('getStatus:', path)

  local info = self.utils.file_info(path)
  local units = {'B', 'KB', 'MB', 'GB'}
  local unit = 1
  local size = info.size
  while size > 1024 do
    size = size / 1024
    unit = unit + 1
    if unit >= #units then break end
  end
  local ext = self.FileType:getExt(item.data)
  local type = self.FileType:getType(ext)
  msg = string.format('type: %s, size: %.2f%s', type, size, units[unit])

  self.log:debug('getStatus: end')

  return msg
end

--------------------------------------------------------------------------------
-- show
--------------------------------------------------------------------------------

-- show play list
-- return: none
function PlayList:show()
  self.log:debug('show: start')

  local pl = mp.get_property('playlist')
  if not pl then
    self.log:error('cannot find play list')
    return
  end

  local cursor = 1
  local list = {}
  self.list = self.utils.parse_json(pl)
  for k, v in pairs(self.list) do
    local _, file = self.utils.split_path(v.filename)
    local ext = self.FileType:getExt(file)
    local name = k .. '. ' .. self.FileType:getIcon(ext) .. file
    if v.current then
      name = '  ' .. name
      cursor = k
    else
      name = '   ' .. name
    end
    table.insert(list, {
		   name = name,
		   data = tostring(k),
    })
  end

  self.showlist:addKey('enter', {
			 key = 'enter',
			 func = function()
			   local list = self.showlist:get()
			   self:open(list)
			 end,
			 opts = { repeatable = false },
  })

  self.showlist:show('󰐑  PlayList', list, function(item)
		       return self:getStatus(item)
  end, tostring(cursor))

  self.log:debug('show: end')
end

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

-- create new instance
-- return: new instance
function PlayList:new()
  local path = mp.find_config_file('scripts')
  package.path = package.path .. ';' .. path .. '/?.lua'

  local Log = require('modules/log')
  local ShowList = require('modules/showlist')

  local _self = setmetatable({
      -- internal data
      utils = require('mp.utils'),
      FileType = require('modules/filetype'),
      log = Log:new('PlayList'),
      showlist = ShowList:new(),
      list = {},
  }, self)
  self.__index = self

  return _self
end

return PlayList
