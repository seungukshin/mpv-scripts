--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local History = {
  name = 'History',
  version = '1.0',
  author = 'Seunguk Shin <seunguk.shin@gmail.com>',
  license = 'MIT - https://opensource.org/licenses/MIT',

  -- configuration
  max = 100,
}

--------------------------------------------------------------------------------
-- callback functions
--------------------------------------------------------------------------------

-- open items
-- items: the cursored directory
--     name: string for display
--     data: string for user data
--     index: index of history
-- return: none
function History:open(items)
  self.log:debug('open: start')

  local history = self.history[items[1].index]
  --mp.commandv('loadfile', history.file, 'replace')
  --mp.add_timeout(1000, function()
		   --mp.commandv('seek', history.seek, 'absolute')
  --end)
  mp.command_native_async({'loadfile', history.file, 'replace'},
    function()
      mp.commandv('seek', history.seek, 'absolute')
  end)
  self.showlist:clear()

  self.log:debug('open: end')
end

-- get file status
-- item: the cursored item
--       name: string for display
--       data: string for user data
--       index: index of history
-- return: file status string
function History:getStatus(item)
  self.log:debug('getStatus: start')

  local index = item.index
  local file = self.history[index].file
  local info = self.utils.file_info(file)
  local msg = ''
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
    local ext = self.FileType:getExt(file)
    local type = self.FileType:getType(ext)
    msg = string.format('type: %s, size: %.2f%s', type, size, units[unit])
  else
    msg = string.format('type: other, size: %.2f%s', size, units[unit])
  end

  self.log:debug('getStatus: end')

  return msg
end

-- update history
-- return: none
function History:update()
  self.log:debug('update: start')

  local file = mp.get_property('path')
  if not file then
    return
  end

  local ext = self.FileType:getExt(file)
  local type = self.FileType:getType(ext)
  if type ~= 'video' and type ~= 'music' then
    return
  end

  local seek = mp.get_property_number('time-pos')
  if not seek then
    return
  end

  table.insert(self.history, {
		 date = os.time(),
		 file = file,
		 seek = seek,
		 length = mp.get_property_number('duration', 0),
  })

  while #self.history  > self.max do
    table.remove(self.history, 1)
  end
  self.updated = true

  self.log:debug('update: end')
end

-- save history file
-- return: none
function History:save()
  self.log:debug('save: start')

  if not self.updated then
    return
  end
  local f = io.open(self.file, 'w')
  local text = f:write(self.utils.format_json(self.history))
  io.close(f)

  self.log:debug('save: end')
end

--------------------------------------------------------------------------------
-- show
--------------------------------------------------------------------------------

-- convert second to hh:mm:ss format string
-- s: seconds
-- return: hh:mm:ss format string
function History:s2t(s)
  local m = s / 60
  s = s % 60
  local h = m / 60
  m = m % 60
  return string.format('%02d:%02d:%02d', h, m, s)
end

-- show history list
-- return: none
function History:show()
  self.log:debug('show: start')

  local list = {}
  for i = #self.history, 1, -1 do
    local path = self.history[i].file
    local _, file = self.utils.split_path(path)
    local ext = self.FileType:getExt(file)
    local name = self.FileType:getIcon(ext) .. file .. '   ' .. self:s2t(self.history[i].seek)
    table.insert(list, {
		   name = name,
		   data = file,
		   index = i,
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

  self.showlist:show('  History', list, function(item)
		       return self:getStatus(item)
  end, 1)

  self.log:debug('show: end')
end

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

-- initialzie history from file
-- return: none
function History:init()
  self.log:debug('init: start')

  local path = mp.find_config_file('scripts')
  path, _ = self.utils.split_path(path)
  self.file = self.utils.join_path(path, 'history.json')

  local text = '{}'
  local f = io.open(self.file, 'r')
  if f then
    text = f:read('*a')
    io.close(f)
  end

  local history = self.utils.parse_json(text)
  for _, v in pairs(history) do
    table.insert(self.history, {
		   date = v.date,
		   file = v.file,
		   seek = v.seek,
		   length = v.length
    })
    self.log:debug(os.date('%FT%X%z', v.date), v.file, v.seek, v.length)
  end

  mp.add_hook('on_unload', 9, function() self:update() end)
  mp.register_event('shutdown', function() self:save() end)

  self.log:debug('init: end')
end

-- create new instance
-- return: new instance
function History:new()
  local path = mp.find_config_file('scripts')
  package.path = package.path .. ';' .. path .. '/?.lua'

  local Log = require('modules/log')
  local ShowList = require('modules/showlist')

  local _self = setmetatable({
      -- internal data
      utils = require('mp.utils'),
      log = Log:new('History'),
      FileType = require('modules/filetype'),
      showlist = ShowList:new(),
      file = nil,
      history = {},
      updated = false,
  }, self)
  self.__index = self

  _self:init()

  return _self
end

return History
