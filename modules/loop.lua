--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local Loop = {
  name = 'Loop',
  version = '1.0',
  author = 'Seunguk Shin <seunguk.shin@gmail.com>',
  license = 'MIT - https://opensource.org/licenses/MIT',

  -- configuratio
  style = '{\\fnInconsolata Nerd Font\\fs12\\alpha&H80\\b1\\bord1}',
  step = 0.5,
}

--------------------------------------------------------------------------------
-- toggle
--------------------------------------------------------------------------------

-- update the screen
-- return: none
function Loop:update()
  self.log:debug('update: start')
  local msg = self.style
  if self.st ~= nil and self.ed ~= nil then
    msg = msg .. 'a-b loop: ' .. self.st .. ' - ' .. self.ed;
  end
  mp.set_osd_ass(0, 0, msg);
  self.log:debug('update: end')
end

-- bind keys in the mapping table
-- return: none
function Loop:bindKeys()
  self.log:debug('bindKeys: start')
  for k, v in pairs(self.map) do
    mp.add_forced_key_binding(v.key, k, v.func, v.opts)
  end
  self.log:debug('bindKeys: end')
end

-- unbind keys in the mapping table
-- return: none
function Loop:unbindKeys()
  self.log:debug('unbindKeys: start')
  for k, _ in pairs(self.map) do
    mp.remove_key_binding(k);
  end
  self.log:debug('unbindKeys: end')
end

-- toggle ab-loop using subtitle time
-- return: none
function Loop:toggle()
  self.log:debug('toggle: start')

  local l = false
  local st = mp.get_property_number('ab-loop-a')
  local ed = mp.get_property_number('ab-loop-b')
  if st == nil or ed == nil then
    self.st = mp.get_property_number('sub-start');
    self.ed = mp.get_property_number('sub-end');
    if self.st ~= nil and self.ed ~= nil then
      l = true
    end
  end
  if l then
    mp.set_property_number('ab-loop-a', self.st)
    mp.set_property_number('ab-loop-b', self.ed)
    self:bindKeys();
  else
    mp.set_property('ab-loop-a', 'no')
    mp.set_property('ab-loop-b', 'no')
    self.st = nil
    self.ed = nil
    self:unbindKeys();
  end
  self:update();

  self.log:debug('toggle: end')
end

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

-- initialize the mapping table for key binding
-- return: none
function Loop:initKeys()
  self.log:debug('initKeys: start')

  self.map = {
    ['st--'] = {
      key = '{',
      func = function()
	self.st = self.st - self.step
	mp.set_property_number('ab-loop-a', self.st)
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['st++'] = {
      key = '}',
      func = function()
	self.st = self.st + self.step
	mp.set_property_number('ab-loop-a', self.st);
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['ed--'] = {
      key = '[',
      func = function()
	self.ed = self.ed - self.step
	mp.set_property_number('ab-loop-b', self.ed)
	self:update()
      end,
      opts = { repeatable = true }
    },
    ['ed++'] = {
      key = ']',
      func = function()
	self.ed = self.ed + self.step
	mp.set_property_number('ab-loop-b', self.ed)
	self:update()
      end,
      opts = { repeatable = true }
    },
  }

  self.log:debug('initKeys: end')
end

-- create new instance
-- return: new instance
function Loop:new()
  local path = mp.find_config_file('scripts')
  package.path = package.path .. ';' .. path .. '/?.lua'

  local Log = require('modules/log')

  local _self = setmetatable({
      -- internal data
      log = Log:new('Loop'),
      st = nil,
      ed = nil,
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

return Loop
