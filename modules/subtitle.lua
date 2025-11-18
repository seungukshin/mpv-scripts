--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local Subtitle = {
  name = 'Subtitle',
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
-- second: true if the subtitle should be loaded as secondary
-- return: none
function Subtitle:open(items, second)
  self.log:debug('open: start')

  if not second then
    mp.set_property('sid', tonumber(items[1].data));
  else
    mp.set_property('secondary-sid', tonumber(items[1].data));
  end
  self.showlist:clear()

  self.log:debug('open: end')
end

-- get file status
-- item: the cursored item
--       name: string for display
--       data: string for user data
-- return: file status string
function Subtitle:getStatus(item)
  self.log:debug('getStatus: start')

  local msg = ''
  if not item then return msg end
  local si = self.list[tonumber(item.data)]
  if not si then return msg end
  local path = si['external-filename']
  if not path then return 'internal' end
  msg = msg .. 'external, '

  local info = self.utils.file_info(path)
  local units = {'B', 'KB', 'MB', 'GB'}
  local unit = 1
  local size = info.size
  while size > 1024 do
    size = size / 1024
    unit = unit + 1
    if unit >= #units then break end
  end

  local ext = self.FileType:getExt(path)
  local type = self.FileType:getType(ext)
  msg = msg .. string.format('type: %s, size: %.2f%s', type, size, units[unit])

  self.log:debug('getStatus: end')

  return msg
end

--------------------------------------------------------------------------------
-- show
--------------------------------------------------------------------------------

-- show play list
-- return: none
function Subtitle:show()
  self.log:debug('show: start')

  local sl = mp.get_property('track-list');
  if not sl then
    self.log:error('cannot find track list')
    return
  end

  local cursor = 1
  local list = {}
  self.list = self.utils.parse_json(sl)
  for k, v in pairs(self.list) do
    if v.type ~= 'sub' then goto continue end
    local file = v['external-filename']
    if file then
      _, file = self.utils.split_path(file)
    else
      file = v.title
    end
    local ext = self.FileType:getExt(file)
    local name = self.FileType:getIcon(ext) .. file
    if v.selected then
      if v['main-selection'] then
	name = '1> ' .. name
	cursor = k
      else
	name = '2> ' .. name
      end
    else
      name = '   ' .. name
    end
    table.insert(list, {
		   name = name,
		   data = tostring(k),
    })
    ::continue::
  end

  self.showlist:addKey('enter', {
			 key = 'enter',
			 func = function()
			   local list = self.showlist:get()
			   self:open(list)
			 end,
			 opts = { repeatable = false },
  })
  self.showlist:addKey('1st-subtitle', {
			 key = '1',
			 func = function()
			   local list = self.showlist:get()
			   self:open(list, false)
			 end,
			 opts = { repeatable = false },
  })
  self.showlist:addKey('2nd-subtitle', {
			 key = '1',
			 func = function()
			   local list = self.showlist:get()
			   self:open(list, true)
			 end,
			 opts = { repeatable = false },
  })

  self.showlist:show('󰨖  Subtitle', list, function(item)
		       return self:getStatus(item)
  end, tostring(cursor))

  self.log:debug('show: end')
end

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

-- create new instance
-- return: new instance
function Subtitle:new()
  local path = mp.find_config_file('scripts')
  package.path = package.path .. ';' .. path .. '/?.lua'

  local Log = require('modules/log')
  local ShowList = require('modules/showlist')

  local _self = setmetatable({
      -- internal data
      utils = require('mp.utils'),
      FileType = require('modules/filetype'),
      log = Log:new('Subtitle'),
      showlist = ShowList:new(),
      list = {},
  }, self)
  self.__index = self

  return _self
end

return Subtitle
