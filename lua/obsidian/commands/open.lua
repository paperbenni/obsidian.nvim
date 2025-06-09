local util = require "obsidian.util"
local RefTypes = require("obsidian.search").RefTypes

---@param client obsidian.Client
---@param path? string|obsidian.Path
local function open_in_app(client, path)
  if not path then
    return client.opts.open.func("obsidian://open?vault=" .. util.urlencode(client:vault_name()))
  end
  path = tostring(path)
  local vault_name = client:vault_name()
  local this_os = util.get_os()

  -- Normalize path for windows.
  if this_os == util.OSType.Windows then
    path = string.gsub(path, "/", "\\")
  end

  local encoded_vault = util.urlencode(vault_name)
  local encoded_path = util.urlencode(path)

  local uri
  if client.opts.open.use_advanced_uri then
    local line = vim.api.nvim_win_get_cursor(0)[1] or 1
    uri = ("obsidian://advanced-uri?vault=%s&filepath=%s&line=%i"):format(encoded_vault, encoded_path, line)
  else
    uri = ("obsidian://open?vault=%s&file=%s"):format(encoded_vault, encoded_path)
  end

  uri = vim.fn.shellescape(uri)

  client.opts.open.func(uri)
end

---@param client obsidian.Client
---@param data CommandArgs
return function(client, data)
  ---@type string|?
  local search_term

  if data.args and data.args:len() > 0 then
    search_term = data.args
  else
    -- Check for a note reference under the cursor.
    local cursor_link, _, ref_type = util.parse_cursor_link()
    if cursor_link ~= nil and ref_type ~= RefTypes.NakedUrl and ref_type ~= RefTypes.FileUrl then
      search_term = cursor_link
    end
  end

  if search_term then
    -- Try to resolve search term to a single note.
    client:resolve_note_async_with_picker_fallback(search_term, function(note)
      vim.schedule(function()
        open_in_app(client, note.path)
      end)
    end, { prompt_title = "Select note to open" })
  else
    -- Otherwise use the path of the current buffer.
    local bufname = vim.api.nvim_buf_get_name(0)
    local path = client:vault_relative_path(bufname)
    open_in_app(client, path)
  end
end
