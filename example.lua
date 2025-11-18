local path = mp.find_config_file('scripts')
package.path = package.path .. ";" .. path .. "/?.lua"

local Log = require('modules/log')
local History = require('modules/history')
local FileList = require('modules/filelist')
local PlayList = require('modules/playlist')
local Subtitle = require('modules/subtitle')
local Loop = require('modules/loop')

local log = Log:new('main');
log:debug('start')

-- enbale history
log:debug('History started')
local history = History:new()
mp.add_forced_key_binding('h', 'history', function()
  log:debug('History opened')
  history:show()
  log:debug('History closed')
end, { repeatable = false })

-- enable file list
mp.add_forced_key_binding('o', 'filelist', function()
  log:debug('FileList started')
  local filelist = FileList:new()
  filelist:show()
  log:debug('FileList ended')
end, { repeatable = false })

-- enable play list
mp.add_forced_key_binding('p', 'playlist', function()
  log:debug('PlayList started')
  local playlist = PlayList:new()
  playlist:show()
  log:debug('PlayList ended')
end, { repeatable = false })

-- enable subtitle list
mp.add_forced_key_binding('s', 'subtitle', function()
  log:debug('Subtitle started')
  local subtitle = Subtitle:new()
  subtitle:show()
  log:debug('Subtitle ended')
end, { repeatable = false })

-- enable loop
mp.add_forced_key_binding('l', 'loop', function()
  log:debug('Loop started')
  local loop = Loop:new()
  loop:toggle()
  log:debug('Loop ended')
end, { repeatable = false })

log:debug('end')
