return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local map = utils.map

  local ls = require('luasnip')
  map({ 'i' }, '<C-K>', function()
    ls.expand()
  end, { silent = true })
  map({ 'i', 's' }, '<C-L>', function()
    ls.jump(1)
  end, { silent = true })
  map({ 'i', 's' }, '<C-J>', function()
    ls.jump(-1)
  end, { silent = true })
  map({ 'i', 's' }, '<C-E>', function()
    if ls.choice_active() then
      ls.change_choice(1)
    end
  end, { silent = true })
end
