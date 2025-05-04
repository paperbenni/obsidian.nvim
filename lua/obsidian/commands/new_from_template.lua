local util = require "obsidian.util"
local log = require "obsidian.log"

---@param client obsidian.Client
---@param data CommandArgs
return function(client, data)
  local picker = client:picker()
  if not picker then
    log.err "No picker configured"
    return
  end

  local title = data.fargs[1]
  local template = data.fargs[2]

  if title ~= nil and template ~= nil then
    local note = client:create_note { title = title, template = template, no_write = false }
    client:open_note(note, { sync = true })
    return
  end

  if title == nil or title == "" then
    title = util.input("Enter title or path (optional): ", { completion = "file" })
    if not title then
      log.warn "Aborted"
      return
    elseif title == "" then
      title = nil
    end
  end

  picker:find_templates {
    callback = function(name)
      if name == nil or name == "" then
        log.warn "Aborted"
        return
      end
      ---@type obsidian.Note
      local note = client:create_note { title = title, template = name, no_write = false }
      client:open_note(note, { sync = false })
    end,
  }
end
