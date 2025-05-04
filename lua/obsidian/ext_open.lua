local Path = require "obsidian.path"
local log = require "obsidian.log"
local util = require "obsidian.util"

local M = {}

-- Default configuration for external file types
M.default_config = {
  -- List of file extensions that should be opened using vim.ui.open
  external_file_types = {
    -- Images
    "png", "jpg", "jpeg", "gif", "bmp", "svg", "webp", "ico", "heic",
    -- Documents
    "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
    -- Audio
    "mp3", "wav", "ogg", "flac", "m4a",
    -- Video
    "mp4", "mkv", "avi", "mov", "wmv",
    -- Archives
    "zip", "tar", "gz", "7z", "rar",
    -- Other
    "exe", "dll"
  }
}

--- Check if a file should be opened externally based on its extension
---@param file_path string The path to the file
---@param config table Optional configuration table
---@return boolean True if the file should be opened externally
function M.should_open_externally(file_path, config)
  config = config or M.default_config
  
  -- Extract file extension
  local ext = file_path:match("%.([^%.]+)$")
  if not ext then 
    return false 
  end
  
  -- Check if extension is in the list of external file types
  ext = ext:lower()
  for _, allowed_ext in ipairs(config.external_file_types) do
    if ext == allowed_ext:lower() then
      return true
    end
  end
  
  return false
end

--- Resolve file path against different potential locations
---@param client obsidian.Client The Obsidian client instance
---@param file_path string The file path to resolve
---@return string|nil The resolved absolute file path or nil if not found
function M.resolve_file_path(client, file_path)
  -- Check if path is absolute and exists
  if Path.new(file_path):is_absolute() then
    if vim.fn.filereadable(file_path) == 1 then
      return file_path
    end
    return nil
  end
  
  -- Try relative to vault root
  local vault_path = tostring(client.dir / file_path)
  if vim.fn.filereadable(vault_path) == 1 then
    return vault_path
  end
  
  -- Try relative to current buffer's directory
  local current_file = vim.fn.expand('%:p')
  if current_file and current_file ~= '' then
    local current_dir = vim.fn.fnamemodify(current_file, ':h')
    local relative_to_current = current_dir .. '/' .. file_path
    if vim.fn.filereadable(relative_to_current) == 1 then
      return relative_to_current
    end
  end
  
  -- Try in attachments folder if configured
  if client.opts.attachments and client.opts.attachments.img_folder then
    local img_folder = Path.new(client.opts.attachments.img_folder)
    if not img_folder:is_absolute() then
      img_folder = client.dir / client.opts.attachments.img_folder
    end
    local in_img_folder = tostring(img_folder / file_path)
    if vim.fn.filereadable(in_img_folder) == 1 then
      return in_img_folder
    end
  end
  
  return nil
end

--- Open a file using the appropriate method based on its type
---@param client obsidian.Client The Obsidian client instance
---@param file_path string The path to the file to open
---@param config table|nil Optional configuration overrides
---@return boolean True if the file was opened successfully
function M.open_file(client, file_path, config)
  config = config or M.default_config
  
  -- Resolve the file path
  local resolved_path = M.resolve_file_path(client, file_path)
  if not resolved_path then
    log.err("File not found: " .. file_path)
    return false
  end
  
  -- Determine how to open the file
  if M.should_open_externally(resolved_path, config) then
    -- Open with external application
    vim.ui.open(resolved_path)
    return true
  else
    -- Open with Neovim
    vim.cmd('edit ' .. vim.fn.fnameescape(resolved_path))
    return true
  end
end

return M