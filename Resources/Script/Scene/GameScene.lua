--[[
Copyright (c) 2013 crosslife <hustgeziyang@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

require "Script/Logic/GameBoardLogic"
require "Script/Sprite/GameIcon"

local scene = nil

local curSelectTag = nil

local NODE_TAG_START = 1000
local NORMAL_TAG = 10
local MATCH_TAG = 30
local SELECT_TAG = 40

local REMOVED_TAG = 2000

local isTouching = false
local isMoving = false
local isRefreshing = false

local touchStartPoint = {}
local touchEndPoint = {}

local touchStartCell = {}
local touchEndCell = {}

local succCellSet = {}
local checkCellSet = {}

local visibleSize = CCDirector:getInstance():getVisibleSize()

--��ʼ������ͼ��
local function initGameBoardIcon()
	for x=1, GBoardSizeX do
		for y = 1, GBoardSizeY do
			--ÿ���ڵ㴴������sprite
			local iconNormalSprite = getGameIconSprite(GIconNormalType, GameBoard[x][y])
			local iconMatchSprite = getGameIconSprite(GIconMatchType, GameBoard[x][y])
			local iconSelectSprite = getGameIconSprite(GIconSelectType, GameBoard[x][y])

			local cell = {x = x, y = y}
			local cellPoint = getCellCenterPoint(cell)

			iconNormalSprite:setTag(NORMAL_TAG)
			iconMatchSprite:setTag(MATCH_TAG)
			iconSelectSprite:setTag(SELECT_TAG)

			iconMatchSprite:setVisible(false)
			iconSelectSprite:setVisible(false)

			local iconNode = CCNode:create()
			iconNode:setTag(NODE_TAG_START + 10 * x + y)

			iconNode:addChild(iconNormalSprite)
			iconNode:addChild(iconMatchSprite)
			iconNode:addChild(iconSelectSprite)
			iconNode:setPosition(CCPoint(cellPoint.x, cellPoint.y))

			scene:addChild(iconNode)
		end
	end
end

--����֮ǰѡ�����ӵ�ѡ��״̬
local function resetSelectGameIcon()
	if curSelectTag ~= nil then
		local cellNode = scene:getChildByTag(NODE_TAG_START + curSelectTag)
		if cellNode ~= nil then
			local normalSprite = cellNode:getChildByTag(NORMAL_TAG)
			local selectSprite = cellNode:getChildByTag(SELECT_TAG)
			if normalSprite ~= nil then 
				normalSprite:setVisible(true)
			end 

			if selectSprite ~= nil then
				selectSprite:setVisible(false)
			end
		end
		curSelectTag = nil
	end
end

--������Ӹ���ͼ��Ч��
local function onClickGameIcon(cell)
	resetSelectGameIcon()

	curSelectTag = 10 * cell.x + cell.y

	scene:getChildByTag(NODE_TAG_START + curSelectTag):getChildByTag(NORMAL_TAG):setVisible(false)
	scene:getChildByTag(NODE_TAG_START + curSelectTag):getChildByTag(SELECT_TAG):setVisible(true)

	AudioEngine.playEffect("Sound/A_select.wav")
end


--�����������ӣ���ִ�лص�����(һ��Ϊ����Ƿ�����)
local function switchCell(cellA, cellB, cfCallBack)
	cclog("switchCell...")
	cclog("cellA.."..cellA.x.." "..cellA.y)
	cclog("cellB.."..cellB.x.." "..cellB.y)
	isTouching = false

	resetSelectGameIcon()

	local tagA = 10 * cellA.x + cellA.y
	local tagB = 10 * cellB.x + cellB.y

	local cellPointA = getCellCenterPoint(cellA)
	local cellPointB = getCellCenterPoint(cellB)

	local nodeA = scene:getChildByTag(NODE_TAG_START + tagA)
	local nodeB = scene:getChildByTag(NODE_TAG_START + tagB)

	if nodeA == nil or nodeB == nil then
		cclog("can't find node!!")
		return
	end

	local moveToA = CCMoveTo:create(0.1, CCPoint(cellPointA.x, cellPointA.y))	

	--�����Ļص���������A cell��
	local function moveAWithCallBack()

		local arrayOfActions = CCArray:create()		
			
		local moveToB = CCMoveTo:create(0.1, CCPoint(cellPointB.x, cellPointB.y))
		arrayOfActions:addObject(moveToB)

		if cfCallBack ~= nil then
			cclog("move with call back..")
			local callBack = CCCallFunc:create(cfCallBack)
			arrayOfActions:addObject(callBack)
		end
		
		local sequence = CCSequence:create(arrayOfActions)
		nodeA:runAction(sequence)
	end

	moveAWithCallBack()
	nodeB:runAction(moveToA)

	--swap tag
	nodeA:setTag(NODE_TAG_START + tagB)
	nodeB:setTag(NODE_TAG_START + tagA)

	--swap index
	GameBoard[cellA.x][cellA.y], GameBoard[cellB.x][cellB.y] = GameBoard[cellB.x][cellB.y], GameBoard[cellA.x][cellA.y]
end

--�Ƴ����ӻص�����
local function cfRemoveSelf(matchSprite)
	cclog("cf remove self")
	if matchSprite == nil then
		cclog("remove failed")
	else
		matchSprite:getParent():removeFromParentAndCleanup(true)
	end
end

--ƥ��������ˢ����Ϸ���
local function cfRefreshBoard()
	cclog("cfRefreshBoard..")
	local firstEmptyCell = nil
	local addCellList = nil
	local moveCellList = nil

	firstEmptyCell, addCellList, moveCellList = getRefreshBoardData()
end

--��Ϊƥ��ͼ�겢�����ص�
local function cfMatchAndFade(node)
	if node ~= nil then
		local normalSprite = node:getChildByTag(NORMAL_TAG)
		local matchSprite = node:getChildByTag(MATCH_TAG)
		local selectSprite = node:getChildByTag(SELECT_TAG)
		if normalSprite ~= nil then 
			normalSprite:setVisible(false)
		end 

		if selectSprite ~= nil then
			selectSprite:setVisible(false)
		end

		if matchSprite ~= nil then
			matchSprite:setVisible(true)

			local arrayOfActions = CCArray:create()		
			
			local fade = CCFadeOut:create(0.5)
			local removeFunc = CCCallFuncN:create(cfRemoveSelf)
			local refreshBoardFunc = CCCallFunc:create(cfRefreshBoard)

			arrayOfActions:addObject(fade)
			arrayOfActions:addObject(removeFunc)
			arrayOfActions:addObject(refreshBoardFunc)
		
			local sequence = CCSequence:create(arrayOfActions)

			matchSprite:runAction(sequence)
		end
	end
end

--��ĳ�����ϵĸ��ӽ������Ƴ�
local function removeCellSet(cellSet)
	for i = 1, #cellSet do
		cclog("remove.."..cellSet[i].x.."  "..cellSet[i].y)
		local tag = 10 * cellSet[i].x + cellSet[i].y
		local node = scene:getChildByTag(NODE_TAG_START + tag)

		--��ʱֱ���������
		node:setTag(REMOVED_TAG + tag)
		GameBoard[cellSet[i].x][cellSet[i].y] = 0

		node:runAction(CCCallFuncN:create(cfMatchAndFade))
	end
end

--���checkCellSet �еĸ����Ƿ�����
local function cfCheckCell()
	cclog("cfCheckCell...")
	local cellA = checkCellSet[1]
	local cellB = checkCellSet[2]

	checkCellSet[1] = nil
	checkCellSet[2] = nil
	if cellA == nil or cellB == nil then
		return
	end

	succCellSet = {}
	if checkCell(cellA) then
		succCellSet[#succCellSet + 1] = cellA
	end

	if checkCell(cellB) then
		succCellSet[#succCellSet + 1] = cellB
	end

	if #succCellSet == 0 then
		--ƥ��ʧ��
		cclog("switch failed...")
		switchCell(cellA, cellB, nil)
		AudioEngine.playEffect("Sound/A_falsemove.wav")
	else
		--ƥ��ɹ�
		cclog("switch success!!!")
		AudioEngine.playEffect("Sound/A_combo1.wav")

		--to do: ִ���������������
		--����ڽ����Ӽ���
		local matchCellSet = {}
		for i = 1, #succCellSet do
			local succCell = succCellSet[i]
			local nearbySet = getNearbyCellSet(succCell)
			for i = 1, #nearbySet do
				matchCellSet[#matchCellSet + 1] = nearbySet[i]
			end
		end
		removeCellSet(matchCellSet)
	end

end


--������
local function createBackLayer()
	local backLayer = CCLayer:create()

	local backSprite = CCSprite:create("imgs/game_bg.png")
	backSprite:setPosition(backSprite:getContentSize().width / 2, backSprite:getContentSize().height / 2)

	backLayer:addChild(backSprite)

	return backLayer
end

--������
local function createTouchLayer()

	local touchColor = Color4B:new(255, 255, 255 ,0)
	local touchLayer = CCLayerColor:create(touchColor)

	touchLayer:changeWidthAndHeight(visibleSize.width, visibleSize.height)

    local function onTouchBegan(x, y)
		--cclog("touchLayerBegan: %.2f, %.2f", x, y)
		isTouching = true
		touchStartPoint = {x = x, y = y}
		touchStartCell = touchPointToCell(x, y)
		if curSelectTag ~= nil then
			local curSelectCell = {x = math.modf(curSelectTag / 10), y = curSelectTag % 10}
			if isTwoCellNearby(curSelectCell, touchStartCell) then
				checkCellSet = {}
				checkCellSet[#checkCellSet + 1] = curSelectCell
				checkCellSet[#checkCellSet + 1] = touchStartCell
				switchCell(curSelectCell, touchStartCell, cfCheckCell)
				return true
			end
		end

		onClickGameIcon(touchStartCell)

        return true
    end

	local function onTouchMoved(x, y)
		--cclog("touchLayerMoved: %.2f, %.2f", x, y)
		local touchCurCell = touchPointToCell(x, y)
		if	isTouching then
			if isTwoCellNearby(touchCurCell, touchStartCell) then
				checkCellSet = {}
				checkCellSet[#checkCellSet + 1] = touchCurCell
				checkCellSet[#checkCellSet + 1] = touchStartCell
				switchCell(touchCurCell, touchStartCell, cfCheckCell)
			end
		end		
    end

	local function onTouchEnded(x, y)
		--cclog("touchLayerEnded: %.2f, %.2f", x, y)
		touchEndPoint = {x = x, y = y}
		touchEndCell = touchPointToCell(x, y)
		isTouching = false
    end


    local function onTouch(eventType, x, y)
        if eventType == "began" then   
            return onTouchBegan(x, y)
		elseif eventType == "moved" then
			return onTouchMoved(x, y)
		elseif eventType == "ended" then
			return onTouchEnded(x, y)
        end
    end

    touchLayer:registerScriptTouchHandler(onTouch)
    touchLayer:setTouchEnabled(true)

	return touchLayer
end


-- create game scene
function CreateGameScene()
   
	scene = CCScene:create()
	scene:addChild(createBackLayer())

	AudioEngine.stopMusic(true)

	local bgMusicPath = CCFileUtils:getInstance():fullPathForFilename("Sound/bgm_game.wav")
	AudioEngine.playMusic(bgMusicPath, true)

	loadGameIcon()

	initGameBoard()
	initGameBoardIcon()

	scene:addChild(createTouchLayer(), 1000)

    return scene
end