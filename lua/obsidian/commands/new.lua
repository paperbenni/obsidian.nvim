local api = require "obsidian.api"
local log = require "obsidian.log"
local Note = require "obsidian.note"

---@param data CommandArgs
return function(_, data)
  ---@type obsidian.Note
  local note
  if data.args:len() > 0 then
    note = Note.create { title = data.args }
  else
    local title = api.input("Enter title or path (optional): ", { completion = "file" })
    if not title then
      log.warn "Aborted"
      return
    elseif title == "" then
      title = nil
    end
    note = Note.create { title = title }
  end

  -- Open the note in a new buffer.
  note:open { sync = true }
  note:write_to_buffer()
end
