--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local ShowList = {
  name = 'ShowList',
  version = '1.0',
  author = 'Seunguk Shin <seunguk.shin@gmail.com>',
  license = 'MIT - https://opensource.org/licenses/MIT',

  -- configuratio
  style = '{\\fnInconsolata Nerd Font\\fs12\\alpha&H80\\b1\\bord1}',
  style_head = '{\\alpha&H80\\1c&H00bbff}',
  style_body = '{\\alpha&H80\\1c&Hffffff}',
  style_foot = '{\\alpha&H80\\1c&H00bbff}',
  style_select = '{\\1c&H4444ff}',
  style_cursor = '{\\alpha&H00}',
  window_foot = 22,
  window_size = 20,
  window_pad = 2,
  filter_keys = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
		 'a', 'b', 'c', 'e', 'd', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
		 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  },
}

--------------------------------------------------------------------------------
-- key events
--------------------------------------------------------------------------------

-- up cursor
-- return: none
function ShowList:up()
  self.log:debug('up: start: cursor:', self.cursor, ', window:', self.window)

  if self.cursor <= 1 then
    -- calculate cursor
    self.cursor = #self.list
    -- calculate window
    if #self.list > self.window_size then
      self.window = #self.list - self.window_size
    else
      self.window = 1
    end
  else
    -- calculate cursor
    self.cursor = self.cursor - 1
    -- calculate window
    if self.cursor - self.window < self.window_pad then
      self.window = self.cursor - self.window_pad
      if self.window < 1 then self.window = 1 end
    end
  end

  self.log:debug('up: end: cursor:', self.cursor, ', window:', self.window)
end

-- down cursor
-- return: none
function ShowList:down()
  self.log:debug('down: start: cursor:', self.cursor, ', window:', self.window)

  if self.cursor >= #self.list then
    -- calculate cursor
    self.cursor = 1
    -- calculate window
    self.window = 1
  else
    -- calculate cursor
    self.cursor = self.cursor + 1
    -- calculate window
    local window_end = self.window + self.window_size
    if window_end - self.cursor < self.window_pad then
      self.window = self.cursor - (self.window_size - self.window_pad)
      local window_max = #self.list - self.window_size
      if self.window > window_max then self.window = window_max end
    end
  end

  self.log:debug('down: end: cursor:', self.cursor, ', window:', self.window)
end

-- page up cursor
-- return: none
function ShowList:pgup()
  self.log:debug('pgup: start')

  for i = 1, self.window_size do
    self:up()
    if self.cursor == 1 then
      break
    end
  end

  self.log:debug('pgup: end')
end

-- page down cursor
-- return: none
function ShowList:pgdown()
  self.log:debug('pgdown: start')

  for i = 1, self.window_size do
    self:down()
    if self.cursor == #self.body then
      break
    end
  end

  self.log:debug('pgdown: end')
end

-- select the cursored item
-- return: none
function ShowList:select(select)
  self.log:debug('select: start')

  local index = self.list[self.cursor]
  if select == nil then
    self.body[index].select = not self.body[index].select
  else
    self.body[index].select = select
  end

  self.log:debug('select: end')
end

-- get selected items
-- return: items
function ShowList:get()
  self.log:debug('get: start')

  local list = {}
  for _, v in pairs(self.body) do
    if v.select then
      table.insert(list, v)
    end
  end
  if #list == 0 then
    local index = self.list[self.cursor]
    table.insert(list, self.body[index])
  end

  self.log:debug('get: end')

  return list
end

-- toggle filter
-- return: none
function ShowList:toggleFilter(filter)
  self.log:debug('toggleFilter: start:', filter)

  if filter == nil then
    self.filterFlag = not self.filterFlag
  else
    self.filterFlag = filter
  end
  if self.filterFlag then
    for _, k in pairs(self.filter_keys) do
      mp.add_forced_key_binding(k, 'filter-' .. k, function()
				  self.filterWord = self.filterWord .. k
				  self:updateList()
				  self:update()
      end, { repeatable = false })
    end
    mp.add_forced_key_binding('bs', 'filter-bs', function()
				self.filterWord = self.filterWord:sub(1, -2)
				self:updateList()
				self:update()
    end, { repeatable = false })
    mp.add_forced_key_binding('esc', 'filter-esc', function()
				self:toggleFilter(false)
				self:updateList()
				self:update()
    end, { repeatable = false })
  else
    self.filterWord = ''
    for _, k in pairs(self.filter_keys) do
      mp.remove_key_binding('filter-' .. k);
    end
    mp.remove_key_binding('filter-bs');
    mp.remove_key_binding('filter-esc');
  end

  self.log:debug('toggleFilter: end')
end

-- toggle help
-- return: none
function ShowList:toggleHelp(help)
  self.log:debug('toggleHelp: start')

  if help == nil then
    self.helpFlag = not self.helpFlag
  else
    self.helpFlag = help
  end
  if self.helpFlag then
    local msg = self.style
    msg = msg .. self.style_head
    msg = msg .. 'help:'
    msg = msg .. self.style_body
    for k, v in pairs(self.map) do
      msg = msg .. '\\N\\h\\h\\h\\h' .. v.key .. ':'
      local l = #v.key
      for i = l, 16 do
	msg = msg .. '\\h'
      end
      msg = msg .. k
    end
    mp.set_osd_ass(0, 0, msg)
  else
    self:update()
  end

  self.log:debug('toggleHelp: end')
end

-- add key binding
-- return: none
function ShowList:addKey(name, key)
  self.log:debug('addKey: start')
  self.map[name] = key
  self.log:debug('addKey: end')
end

--------------------------------------------------------------------------------
-- show and clear
--------------------------------------------------------------------------------

-- bind keys in the mapping table
-- return: none
function ShowList:bindKeys()
  self.log:debug('bindKeyse: start')
  for k, v in pairs(self.map) do
    mp.add_forced_key_binding(v.key, k, v.func, v.opts)
  end
  self.log:debug('bindKeyse: end')
end

-- unbind keys in the mapping table
-- return: none
function ShowList:unbindKeys()
  self.log:debug('unbindKeyse: start')
  for k, _ in pairs(self.map) do
    mp.remove_key_binding(k);
  end
  self.log:debug('unbindKeyse: end')
end

-- update the screen
-- return: none
function ShowList:update()
  self.log:debug('update: start:', self.cursor, self.window, #self.list)

  self.helpFlag = false
  local msg = self.style
  -- head
  local head = ''
  if type(self.head) == 'string' then
    head = self.head
  elseif type(self.head) == 'function' then
    local index = self.list[self.cursor]
    head = self.head(self.body[index])
  end
  msg = msg .. self.style_head .. head
  msg = msg .. ' [' .. self.cursor .. '/' .. #self.list .. ']'
  if self.filterFlag then
    msg = msg .. ' (filter: ' .. self.filterWord .. ')'
  end
  -- body
  local i = 1 -- index for window
  local b = self.window -- index for body
  msg = msg .. self.style_body
  while i <= self.window_size + 1 do
    if (i == 1 and b ~= 1) or
      (i == self.window_size + 1 and b < #self.list) then
      msg = msg .. '\\N...'
    else
      if b <= #self.list then
	msg = msg .. '\\N'
	if b == self.cursor then
	  msg = msg .. self.style_cursor
	end
	if self.body[self.list[b]].select then
	  msg = msg .. self.style_select
	end
	msg = msg .. self.body[self.list[b]].name
	if self.body[self.list[b]].select or b == self.cursor then
	  msg = msg .. self.style_body
	end
      else
	msg = msg .. '\\N' .. ' '
      end
    end
    i = i + 1
    b = b + 1
  end
  -- foot
  local foot = ''
  if type(self.foot) == 'string' then
    foot = self.foot
  elseif type(self.foot) == 'function' then
    local index = self.list[self.cursor]
    foot = self.foot(self.body[index])
  end
  msg = msg .. '\\N' .. self.style_foot .. foot
  -- display
  mp.set_osd_ass(0, 0, msg)

  self.log:debug('update: end')
end

-- update list
-- cursor: cursor line number or data
-- return: none
function ShowList:updateList(cursor)
  self.log:debug('updateList: start: cursor')

  -- find the data for the cursor
  local index
  local data
  if type(cursor) == 'string' then
    data = cursor
  else
    if type(cursor) == 'number' then
      index = self.list[cursor]
    else
      index = self.list[self.cursor]
    end
    if not index or index < 1 or index > #self.body then
      index = 1
    end
    data = self.body[index].data
  end

  -- filter
  index = 1
  self.list = {}
  local match = false
  if self.filterWord == '' then
    for i = 1, #self.body do
      self.list[i] = i
      if not match and self.body[i].data == data then
	self.cursor = index
	match = true
      end
      index = index + 1
    end
  else
    for k, v in pairs(self.body) do
      if v.data:lower():find(self.filterWord) then
	table.insert(self.list, k)
	if not match and v.data == data then
	  self.cursor = index
	  match = true
	end
	index = index + 1
      end
    end
  end
  if self.cursor < 1 then self.cursor = 1
  elseif self.cursor > #self.list then self.cursor = #self.list end
  self.window = self.cursor - self.window_size / 2
  if #self.list <= self.window_size then self.window = 1 end
  if self.window < 1 then self.window = 1 end

  self.log:debug('updateList: end')
end

-- show list
-- head: string or func(item) which returns string for head
-- body: table for body
--       name: string for display
--       data: string for user data
-- foot: string or func(item) which returns string for foot
-- cursor: cursor line number or data
-- return: none
function ShowList:show(head, body, foot, cursor)
  self.log:debug('show: start')

  self.head = head
  self.body = body
  self.foot = foot
  self.filterFlag = false
  self.filterWord = ''
  self.helpFlag = false
  self:updateList(cursor)
  self:update()
  self:bindKeys()

  self.log:debug('show: end')
end

-- clear the screen
-- return: none
function ShowList:clear()
  self.log:debug('clear: start')

  self.head = nil
  self.body = {}
  self.list = {}
  self.foot = nil
  self.cursor = 0
  self.window = 0
  self.filterFlag = false
  self.filterWord = ''
  self.helpFlag = false
  mp.set_osd_ass(0, 0, '')
  self:toggleFilter(false)
  self:unbindKeys()

  self.log:debug('clear: end')
end

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

-- initialize the mapping table for key binding
-- return: none
function ShowList:initKeys()
  self.log:debug('initKeys: start')

  self.map = {
    ['up'] = {
      key = 'up',
      func = function()
	self:up()
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['down'] = {
      key = 'down',
      func = function()
	self:down()
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['pageup'] = {
      key = 'kp_pgup',
      func = function()
	self:pgup()
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['pagedown'] = {
      key = 'kp_pgdwn',
      func = function()
	self:pgdown()
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['select'] = {
      key = 'space',
      func = function()
	self:select()
	self:update()
      end,
      opts = { repeatable = false }
    },
    ['quit'] = {
      key = 'esc',
      func = function()
	self:clear()
      end,
      opts = { repeatable = false }
    },
    ['filter'] = {
      key = 'f',
      func = function()
	self:toggleFilter()
	self:update()
      end,
      opts = { repeatable = false }
    },
    ['help'] = {
      key = 'h',
      func = function()
	self:toggleHelp()
      end,
      opts = { repeatable = false }
    },
  }

  self.log:debug('initKeys: end')
end

-- create new instance
-- return: new instance
function ShowList:new()
  local path = mp.find_config_file('scripts')
  package.path = package.path .. ';' .. path .. '/?.lua'

  local Log = require('modules/log')

  local _self = setmetatable({
      -- internal data
      log = Log:new('ShowList'),

      -- head: string or func(item)
      head = nil,
      -- body[index]
      --     name: string = display name
      --     data: string = name
      --     select: boolean = selected or not
      body = {},
      -- filtered body
      list = {},
      -- foot: string or func(item)
      foot = nil,
      -- cursor: int = index of self.list for cursor
      cursor = 0,
      -- window: int = index of self.list for the first line of window
      window = 1,
      -- filterFlag: boolean
      filterFlag = false,
      -- filterWord: string
      filterWord = '',
      -- helpFlag: boolean
      helpFlag = false,
      -- map[name]
      --    key: string = key
      --    func: func() = function
      --    opts: {} = option
      map = {},
  }, self)
  self.__index = self

  _self:initKeys()

  return _self
end

return ShowList
