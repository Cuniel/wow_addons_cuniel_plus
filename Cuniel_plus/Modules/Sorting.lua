local _, NS = ...
-- Port of the installed ShestakUI 11.2.5 Modules/Blizzard/Bags.lua:
-- BS_clearData, SortOnUpdate, SortBags. Original: Stuffing / Hungtar / Tukz / ShestakUI.
-- Sort keys, descending comparison and reverse-slot destinations are retained.
-- Adapter changes: Bagnon bag selection, modern container info, cursor/lock guards.
local Sort = CreateFrame("Frame")
NS.Sorting = Sort
local tinsert, strmatch = table.insert, string.match
local function GetContainerItemInfo(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info then return info.iconFileID, info.stackCount, info.isLocked, info.quality end
end
local BS_bagGroups
local BS_itemSwapGrid

local function RetryAfterItemLoad(self)
	if self.waitingForItems then return end
	self.waitingForItems = true
	C_Timer.After(0.25, function()
		self.waitingForItems = nil
		if not self.active then return end
		if not self.valid() then
			self:Stop("整理已停止：窗口关闭、仓库切换或进入战斗。")
			return
		end
		self:SortBags()
	end)
end

local function BS_clearData()
	BS_itemSwapGrid = {}
	BS_bagGroups = {}
end

function Sort:SortOnUpdate(elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed

	if self.elapsed < 0.05 then
		return
	end

	self.elapsed = 0

    if self.pendingMove then
        local pending = self.pendingMove
        local moved = C_Container.GetContainerItemInfo(pending.bag, pending.slot)
        if moved and not moved.isLocked and moved.hyperlink == pending.item.link and moved.stackCount == pending.item.count then
            self.pendingMove = nil
        elseif GetTime() - pending.time > 3 then
            self:Stop("物品移动或堆叠结果变化，请等待背包更新后再次整理。"); return
        else return end
    end
	local changed = false
	local blocked = false

	for bagIndex in pairs(BS_itemSwapGrid) do
		for slotIndex in pairs(BS_itemSwapGrid[bagIndex]) do
			local destinationBag = BS_itemSwapGrid[bagIndex][slotIndex].destinationBag
			local destinationSlot = BS_itemSwapGrid[bagIndex][slotIndex].destinationSlot

			local _, _, locked1 = GetContainerItemInfo(bagIndex, slotIndex)
			local _, _, locked2 = GetContainerItemInfo(destinationBag, destinationSlot)

			if locked1 or locked2 then
				blocked = true
			elseif bagIndex ~= destinationBag or slotIndex ~= destinationSlot then
				C_Container.PickupContainerItem(bagIndex, slotIndex)
                if not GetCursorInfo() then self:Stop("游戏未允许移动物品，已停止整理。"); return end
                C_Container.PickupContainerItem(destinationBag, destinationSlot)
                if GetCursorInfo() then C_Container.PickupContainerItem(bagIndex, slotIndex) end
                if GetCursorInfo() then self:Stop("物品仍在鼠标上，请放下后重试。"); return end
                self.pendingMove = {bag=destinationBag, slot=destinationSlot,
                    item=BS_itemSwapGrid[bagIndex][slotIndex], time=GetTime()}

				local tempItem = BS_itemSwapGrid[destinationBag][destinationSlot]
				BS_itemSwapGrid[destinationBag][destinationSlot] = BS_itemSwapGrid[bagIndex][slotIndex]
				BS_itemSwapGrid[bagIndex][slotIndex] = tempItem

				changed = true
				return
			end
		end
	end

	if not changed and not blocked then
		self:Stop("整理完成。")
	end
end

function Sort:SortBags()
	BS_clearData()

	local bagList = self.selectedBags
	local missingItems = {}

	for _, slotNum in pairs(bagList) do
		if C_Container.GetContainerNumSlots(slotNum) > 0 then
			BS_itemSwapGrid[slotNum] = {}
			local family = select(2, C_Container.GetContainerNumFreeSlots(slotNum))
			if family then
				if family == 0 then family = "Default" end
				if not BS_bagGroups[family] then
					BS_bagGroups[family] = {}
					BS_bagGroups[family].bagSlotNumbers = {}
				end
				table.insert(BS_bagGroups[family].bagSlotNumbers, slotNum)
			end
		end
	end

	for _, group in pairs(BS_bagGroups) do
		group.itemList = {}
		for _, bagSlot in pairs(group.bagSlotNumbers) do
			for itemSlot = 1, C_Container.GetContainerNumSlots(bagSlot) do
				local itemLink = C_Container.GetContainerItemLink(bagSlot, itemSlot)
				if itemLink ~= nil then
					local newItem = {}
                    local info = C_Container.GetContainerItemInfo(bagSlot, itemSlot)
                    newItem.link, newItem.count = itemLink, info and info.stackCount or 1

					local n, _, q, iL, rL, c1, c2, _, Sl, _, _, classID = C_Item.GetItemInfo(itemLink)
					local itemID, itemType, itemSubType, equipLoc, _, instantClassID, instantSubClassID = C_Item.GetItemInfoInstant(itemLink)
					local p = 1
					-- Hearthstone
					if itemID == 6948 or itemID == 110560 or itemID == 140192 then
						p = 99
					elseif itemID == 141605 then -- Flight Master's Whistle
						p = 98
					elseif itemID == 128353 then -- Admiral's Compass
						p = 97
					end
					-- Item names and categories are server-cached. Request missing records and
					-- resume automatically; a single uncached item must not cancel the sort.
					if not n and not itemLink:find("battlepet:", 1, true) then
						itemID = itemID or (info and info.itemID)
						if itemID then
							missingItems[itemID] = true
							if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
						end
					end
					-- Fix for battle pets
					if not n and itemLink:find("battlepet:", 1, true) then
						n = itemLink
						q = select(4, GetContainerItemInfo(bagSlot, itemSlot))
						iL = 1
						rL = 1
						c1 = "Pet"
						c2 = "Pet"
						Sl = ""
					end

					-- After a short wait, fall back to instant data. This covers obsolete or
					-- malformed links for which GET_ITEM_INFO_RECEIVED never succeeds.
					if not n then
						n = itemLink:match("%[(.-)%]") or tostring(itemID or itemLink)
						q = q or (info and info.quality) or 0
						iL, rL = iL or 0, rL or 0
						c1 = c1 or itemType or tostring(instantClassID or 99)
						c2 = c2 or itemSubType or tostring(instantSubClassID or 99)
						Sl = Sl or equipLoc or ""
						classID = classID or instantClassID
					end

					-- Keystone
					local ks = strmatch(itemLink, "keystone:(%d+)")
					if ks then
						p = 10
					end

					if classID == 0 then	-- Consumable
						p = 9
					elseif classID == 2 or classID == 4 then	-- Weapon and Armor
						p = 8
					end

					newItem.sort = p..q..c1..c2..rL..n..iL..Sl

					tinsert(group.itemList, newItem)

					BS_itemSwapGrid[bagSlot][itemSlot] = newItem
					newItem.startBag = bagSlot
					newItem.startSlot = itemSlot
				end
			end
		end

		table.sort(group.itemList, function(a, b)
			return a.sort > b.sort
		end)

		for index, item in pairs(group.itemList) do
			local gridSlot = index
			for _, bagSlotNumber in pairs(group.bagSlotNumbers) do
				if gridSlot <= C_Container.GetContainerNumSlots(bagSlotNumber) then
					BS_itemSwapGrid[item.startBag][item.startSlot].destinationBag = bagSlotNumber
					BS_itemSwapGrid[item.startBag][item.startSlot].destinationSlot = C_Container.GetContainerNumSlots(bagSlotNumber) - gridSlot + 1
					break
				else
					gridSlot = gridSlot - C_Container.GetContainerNumSlots(bagSlotNumber)
				end
			end
		end
	end

	if next(missingItems) and GetTime() < (self.itemLoadDeadline or 0) then
		BS_clearData()
		if not self.itemLoadNotice then
			self.itemLoadNotice = true
			NS:Print("正在加载物品资料，完成后会自动整理。")
		end
		RetryAfterItemLoad(self)
		return
	end
	self.itemLoadNotice = nil

	self:SetScript("OnUpdate", function(frame, elapsed)
        if InCombatLockdown() or not frame.valid() then frame:Stop("整理已停止：窗口关闭、仓库切换或进入战斗。"); return end
        if GetTime() - frame.started > 300 then frame:Stop("整理超时，已停止。"); return end
        if GetCursorInfo() then frame:Stop("请先放下鼠标上的物品后重试。"); return end
        Sort.SortOnUpdate(frame, elapsed)
    end)
end


function Sort:Stop(message)
    self:SetScript("OnUpdate", nil)
    self.active, self.pendingMove, self.waitingForItems = nil, nil, nil
	self.itemLoadDeadline, self.itemLoadNotice = nil, nil
    BS_clearData()
    if message then NS:Print(message) end
end
function Sort:Start(bags, bank, valid)
    if self.active then self:Stop("已停止整理。"); return end
    if InCombatLockdown() then NS:Print("请脱离战斗后整理。"); return end
    if GetCursorInfo() then NS:Print("请先放下鼠标上的物品。"); return end
    if not valid() then NS:Print("当前仓库不可操作。"); return end
    self.selectedBags = {}
    local reagent = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or 5
    for _, bag in ipairs(bags) do
        -- Original ShestakUI backpack sort uses bags 4..0, not the reagent bag.
        if (bank or (bag >= 0 and bag < reagent)) and bag ~= (REAGENTBANK_CONTAINER or -3) then
            self.selectedBags[#self.selectedBags + 1] = bag
        end
    end
    if #self.selectedBags == 0 then NS:Print("没有可整理的普通背包格子。"); return end
    table.sort(self.selectedBags, function(a,b) return a>b end)
    self.valid, self.started, self.elapsed, self.active = valid, GetTime(), 0, true
	self.itemLoadDeadline, self.itemLoadNotice, self.waitingForItems = GetTime() + 3, nil, nil
    self:SortBags()
end
