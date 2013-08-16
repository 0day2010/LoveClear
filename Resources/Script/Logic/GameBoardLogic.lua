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

require "Script/Config/CommonDefine"

--��ʼ�������и���index��Ϊ0
GameBoard = {}
for i = 1, GBoardSizeX do
	GameBoard[i] = {}
	for j = 1, GBoardSizeY do
		GameBoard[i][j] = 0
	end
end

--������ɳ�ʼ���̣���֤��������
function initGameBoard()
	for	x = 1, GBoardSizeX do
		for y = 1, GBoardSizeY do
			repeat				
				math.randomseed(math.random(os.time()))
				GameBoard[x][y] = math.random(GGameIconCount)
			until checkCell({x = x, y = y}) == false
		end
	end
end

--������ת��Ϊ���̸��ӵ�
function touchPointToCell(x, y)
	local cellX = math.modf((x - GLeftBottomOffsetX) / GCellWidth)
	local cellY = math.modf((y - GLeftBottomOffsetY) / GCellWidth)
	local cell = {}
	cell.x = cellX + 1
	cell.y = cellY + 1

	if cell.x > GBoardSizeX then
		cell.x = GBoardSizeX
	end

	if cell.y > GBoardSizeY then
		cell.y = GBoardSizeY
	end

	return cell
end

--��ȡĳ�����ӵ���������
function getCellCenterPoint(cell)
	local point = {}
	point.x = (cell.x - 1) * GCellWidth + GLeftBottomOffsetX + GCellWidth / 2
	point.y = (cell.y - 1) * GCellWidth + GLeftBottomOffsetY + GCellWidth / 2

	return point
end

--������������Ƿ�����
function isTwoCellNearby(cellA, cellB)
	local ret = false
	if (math.abs(cellA.x - cellB.x) == 1 and cellA.y == cellB.y) or
	   (math.abs(cellA.y - cellB.y) == 1 and cellA.x == cellB.x) then
		ret = true
	end	
	return ret
end

--���ĳ�������Ƿ����3��,����GameBoard����
function checkCell(cell)
	local x = cell.x
	local y = cell.y

	local index = GameBoard[x][y]

	local ret = false
	--�����ţ������Ż�
	if x > 1 and GameBoard[x-1][y] == index then
		if (x > 2 and GameBoard[x-2][y] == index) or (x < GBoardSizeX and GameBoard[x+1][y] == index) then
			ret = true
		end
	end

	if x < GBoardSizeX and GameBoard[x+1][y] == index then
		if (x < GBoardSizeX-1 and GameBoard[x+2][y] == index) or (x > 1 and GameBoard[x-1][y] == index) then
			ret = true
		end
	end

	if y > 1 and GameBoard[x][y-1] == index then
		if (y > 2 and GameBoard[x][y-2] == index) or (y < GBoardSizeY and GameBoard[x][y+1] == index) then
			ret = true
		end
	end

	if y < GBoardSizeY and GameBoard[x][y+1] == index then
		if (y < GBoardSizeY-1 and GameBoard[x][y+2] == index) or (y > 1 and GameBoard[x][y-1] == index) then
			ret = true
		end
	end
	return ret
end

--�����ĳ������ͬɫ�����ĸ��Ӽ���
function getNearbyCellSet(cell)
	local x = cell.x
	local y = cell.y
	local index = GameBoard[x][y]

	local cellSet = {}
	cellSet[#cellSet + 1] = {x = x, y = y}
	if x > 1 and GameBoard[x-1][y] == index then
		cellSet[#cellSet + 1] = {x = x-1, y = y}
		if (x > 2 and GameBoard[x-2][y] == index) then
			cellSet[#cellSet + 1] = {x = x-2, y = y}
		end
	end

	if x < GBoardSizeX and GameBoard[x+1][y] == index then
		cellSet[#cellSet + 1] = {x = x+1, y = y}
		if (x < GBoardSizeX-1 and GameBoard[x+2][y] == index) then
			cellSet[#cellSet + 1] = {x = x+2, y = y}
		end
	end

	if y > 1 and GameBoard[x][y-1] == index then
		cellSet[#cellSet + 1] = {x = x, y = y-1}
		if (y > 2 and GameBoard[x][y-2] == index) then
			cellSet[#cellSet + 1] = {x = x, y = y-2}
		end
	end

	if y < GBoardSizeY and GameBoard[x][y+1] == index then
		cellSet[#cellSet + 1] = {x = x, y = y+1}
		if (y < GBoardSizeY-1 and GameBoard[x][y+2] == index) then
			cellSet[#cellSet + 1] = {x = x, y = y+2}
		end
	end
	return cellSet
end

--���������������������������������
function getRefreshBoardData()
	
	--��¼ÿ����������Ŀո�
	local firstEmptyCell = {}

	--��¼ÿ������Ҫ���ӵ�����
	local addCellList = {}

	--��¼ÿ����Ҫ�ƶ�������
	local moveCellList = {}

	for i = 1, GBoardSizeX do
		for j = 1, GBoardSizeY do
			if GameBoard[i][j] == 0 then
				if firstEmptyCell[i] == nil then
					firstEmptyCell[i] = {x = i, y = j}
				end

				--�������index�������Ӧ�е�addList
				math.randomseed(math.random(os.time()))
				local addIconIndex = math.random(GGameIconCount)

				if addCellList[i] == nil then
					addCellList[i] = {}
				end
				addCellList[i][#(addCellList[i]) + 1] = addIconIndex
			else
				if moveCellList[i] == nil then
					moveCellList[i] = {}
				end
				--�ж��Ƿ��Ѿ��������սڵ�
				if firstEmptyCell[i] ~= nil then					
					moveCellList[i][#(moveCellList[i]) + 1] = {x = i, y = j}
				end
			end
		end
	end

	return firstEmptyCell, addCellList, moveCellList
end
