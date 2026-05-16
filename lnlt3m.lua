math.randomseed(os.time())
local game_state = {" "," "," "," "," "," "," "," "," "}
local model = {}
model.__index = model

function model.new(is_X,center_weight,corner_weight,edge_weight,win_rew,tie_rew,loss_rew) return setmetatable({mstate = {},his = {},is_X = is_X or false,center_weight = center_weight or 10, corner_weight = corner_weight or 10,edge_weight = edge_weight or 10,win_rew = win_rew or 5,tie_rew = tie_rew or 2, loss_rew = loss_rew or -5},model) end

function model:find_moves_and_construct(st)
  local tmp_mstate_slice = {}
  for i = 1,9 do if st[i] == " " then tmp_mstate_slice[i] = ((i == 5 and self.center_weight ) or ((i == 1 or i == 3 or i == 7 or i == 9) and self.corner_weight )) or self.edge_weight end end
  return tmp_mstate_slice
end
function model:update(w)
  if not w then return end
  local rew,sign = 0, (self.is_X and "X" or "O")
  if w == sign then rew = self.win_rew elseif w == "Tie" then rew = self.tie_rew else rew = self.loss_rew end
  for _,e in ipairs(self.his) do self.mstate[e.state][e.move] = math.max(1,self.mstate[e.state][e.move] + rew) end
  self.his = {}
end
function model:think(st)
  local st_str = table.concat(st)
  if not self.mstate[st_str] then self.mstate[st_str] = self:find_moves_and_construct(st) end
  local available = {}
  for move,weight in pairs(self.mstate[st_str]) do for i=1,weight do available[#available + 1] = move end end
  if #available == 0 then for i=1,9 do if st[i] == " " then available[#available + 1] = i end end end
  local m_posnum = available[math.random(#available)]
  self.his[#self.his + 1] = {state = st_str, move = m_posnum}
  return m_posnum
end

local function clrscr() io.write("\27[2J\27[H") end

local function checkwinner(st)
  local wins = { {1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {1, 4, 7}, {2, 5, 8}, {3, 6, 9}, {1, 5, 9}, {3, 5, 7} }
  for _, c in ipairs(wins) do if st[c[1]] ~= " " and st[c[1]] == st[c[2]] and st[c[1]] == st[c[3]] then return st[c[1]] end end
  for i = 1, 9 do if st[i] == " " then return nil end end
  return "Tie"
end

local function visualise(st) io.write("-------------\n| "..st[1].." | "..st[2].." | "..st[3].." |\n-------------\n| "..st[4].." | "..st[5].." | "..st[6].." |\n-------------\n| "..st[7].." | "..st[8].." | "..st[9].." |\n-------------\n"); io.flush()end

local t3_ai,train_comp = model.new(false,15,12,10,5,2,-5), model.new(true,15,12,10,5,2,-5)
local t3_win,tc_win,ties_win = 0,0,0
for i = 1, 5000 do
  local ai_game_state = {" "," "," "," "," "," "," "," "," "}
  local turn = "X"
  while not checkwinner(ai_game_state) do local move; if turn == "X" then ai_game_state[train_comp:think(ai_game_state)],turn = "X","O" else ai_game_state[t3_ai:think(ai_game_state)],turn = "O","X" end end
  local winner = checkwinner(ai_game_state)
  t3_ai:update(winner)
  train_comp:update(winner)
  if winner == "X" then tc_win = tc_win + 1 elseif winner == "Tie" then ties_win = ties_win + 1 else t3_win = t3_win + 1 end
  if i % 10 == 0 then clrscr() visualise(ai_game_state) io.write(i.." games played for training\nX: "..tc_win.."\nO: "..t3_win.."\nTies: "..ties_win.."\n") io.flush() end
end

train_comp = nil
while true do
  clrscr()
  visualise(game_state)
  local posnum
  repeat
    io.write("Mark X at (1-9): ")
    io.flush()
    posnum = tonumber(io.read())
    if not posnum or not (posnum >= 1 and posnum <= 9) or game_state[posnum] ~= " " then io.write("invalid move. try again\n") io.flush(); posnum = nil end
  until posnum
  game_state[posnum] = "X"
  local winner = checkwinner(game_state)
  if not winner then
    local m_posnum = t3_ai:think(game_state)
    game_state[m_posnum] = "O"
    winner = checkwinner(game_state)
  end
  if winner then
    clrscr()
    visualise(game_state)
    t3_ai:update(winner)
    io.write((winner == "Tie" and "It's a Tie") or (winner .. " won"))
    io.write("\n\npress any key to proceed")
    io.flush() io.read()
    game_state = {" "," "," "," "," "," "," "," "," "}
  end
end
