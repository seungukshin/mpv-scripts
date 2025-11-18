--------------------------------------------------------------------------------
-- class metadata
--------------------------------------------------------------------------------
local FileType = {
  name = 'FileType',
  version = '1.0',
  author = 'Seunguk Shin <seunguk.shin@gmail.com>',
  license = 'MIT - https://opensource.org/licenses/MIT',

  -- configuratio
  filetypes = {
    ['mkv'] = 'video',
    ['mp4'] = 'video',
    ['avi'] = 'video',
    ['mov'] = 'video',
    ['ts'] = 'video',
    ['flac'] = 'music',
    ['ogg'] = 'music',
    ['mp3'] = 'music',
    ['jpeg'] = 'image',
    ['jpg'] = 'image',
    ['srt'] = 'subtitle',
    ['smi'] = 'subtitle',
  },
  fileicons = {
    ['video'] = '  ',
    ['music'] = '  ',
    ['image'] = '  ',
    ['subtitle'] = '󰨖  ',
    ['other'] = '  ',
  },
}

--------------------------------------------------------------------------------
-- exteranl functions
--------------------------------------------------------------------------------
-- get file extension
-- name: file name
-- return: extension of file name
function FileType:getExt(name)
  local ext = name:match('.[^.]*$')
  if ext:sub(1, 1) == '.' then ext = ext:sub(2) end
  return ext
end

-- get file type
-- ext: extension
-- return: 'video', 'music', 'image', 'subtitle', or 'other'
function FileType:getType(ext)
  local type = self.filetypes[ext]
  if type then
    return type
  end
  return 'other'
end

-- get file icon
-- ext: extension
-- return:  ,  ,  , 󰨖 , or 
function FileType:getIcon(ext)
  return self.fileicons[FileType:getType(ext)]
end

return FileType
