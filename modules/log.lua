local Log = {
  name = 'Log',
  version = '1.0',
  author = 'Seunguk Shin <seunguk.shin@gmail.com>',
  license = 'MIT - https://opensource.org/licenses/MIT',
}

-- print an error message
-- ...: data to print
-- return: none
function Log:error(...)
  mp.msg.error(self.mod, ...);
end

-- print a warningr message
-- ...: data to print
-- return: none
function Log:warn(...)
  mp.msg.warn(self.mod, ...);
end

-- print an information message
-- ...: data to print
-- return: none
function Log:info(...)
  mp.msg.info(self.mod, ...);
end

-- print a debug message
-- ...: data to print
-- return: none
function Log:debug(...)
  mp.msg.debug(self.mod, ...);
end

-- create new instance
-- mod: module name
-- return: new instance
function Log:new(mod)
  local _self = setmetatable({
      -- internal data
      mod = '[' .. mod .. ']',
  }, self)
  self.__index = self

  return _self
end

return Log
