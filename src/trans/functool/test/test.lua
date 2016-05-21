--面对设计文档有种对生活失去了信心的赶脚，不要费力气改了，重写一个把
Include("\\script\\function\\cdkey\\ck_define.lua")
Include("\\script\\lib\\globalfunctions.lua")
Include("\\script\\lib\\talktmp.lua")
Include("\\script\\lib\\date.lua")
Include("\\script\\misc\\taskmanager.lua")
Include("\\script\\task\\global_task\\gtask_data.lua")
Include("\\script\\online_activites\\activity_head.lua")

CK_TASK_GROUP = TaskManager:Create(CK_TASK_GROUP[1], CK_TASK_GROUP[2]);
CK_TASK_GROUP.Task1 = 1 --1,2,3位分别表示武林新秀，老战友，活跃着,4-11位勇往直前任务，百战杀怪任务12-16记录,17-21完成,百战副本任务22-26记录，27-31接取
CK_TASK_GROUP.Task2 = 2 --百战副本任务1-5可交，6-10完成，--百战PVP任务11-17记录，18-24接取，25-31可交
CK_TASK_GROUP.Task3 = 3 --百战PVP任务1-7完成,8-10杀怪加成，11-13副本加成，14-16pvp加成, 17+是速战速决任务
CK_TASK_GROUP.Task4 = 4 --任务标记
CK_TASK_GROUP.Task5 = 5 --大富翁消费任务计数
CK_TASK_GROUP.Score = 6 --活跃度
CK_TASK_GROUP.Award = 7 --按位标记奖励

CK_NPC_NAME = "<color=green>活动大使：<color>";
CK_NPC_TITLE = "快来邀请朋友们一起来玩游戏吧，和更多的朋友一起玩游戏，快乐会更多哦！";

CK_NPC_DIALOG = {
	"活动介绍/ck_ActInfo",
	"激活称号/ck_ActTilte",
	"勇往直前任务/ck_TaskForward",
	"百战不殆任务/ck_BaiZhanBuDai",
	"速战速决任务/ck_FastTask",
	"大富翁任务/ck_ZiloTask",
	"活跃度查询/ck_QueryScore",
	"天骄令查询/cdk_QueryUseTianJiaoLingNum",
	"活跃度兑换奖励/ck_ScoreAward",
}

function cdk_QueryUseTianJiaoLingNum()
	Say(CK_NPC_NAME..format("%s当前累计使用天骄令数量为<color=gold>%d<color>!", gf_GetPlayerSexName(), ck_GetCostIB()), 0);	
end

--活动是否开启
function ck_IsOpen()
	return gf_CheckDuration(CK_START_TIME, CK_END_TIME);		
end

--每日清理
function ck_DailyReset()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	--重置百战不殆任务
	for i = 12, 31 do
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, i, 0);
	end
	CK_TASK_GROUP:SetTask(CK_TASK_GROUP.Task2, 0); 
	for i = 1, 16 do
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, i, 0);
	end
	--删除百战不殆的任务
	for i = 234, 238 do
		DirectDeleteTask(i)
	end
end

--获得当天索引
function ck_GetRandIndex(nMax)
	local today = Date();
	local wDay = today:week();
	if wDay == 0 then wDay = 7 end
	return mod(wDay, nMax) + 1;	
end

--获取类型
function ck_GetTitleType()
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 1) == 1 then
		return 1;
	end
--	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 2) == 1 then
--		return 2;
--	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 3) == 1 then
		return 3;
	end
	return 0;
end

--获得贡献度
function ck_GetCkScore()
	return CK_TASK_GROUP:GetTask(CK_TASK_GROUP.Score);
end

--增加积分
function ck_AddCkScore(nAdd)
	if not nAdd or nAdd < 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTask(CK_TASK_GROUP.Score, CK_TASK_GROUP:GetTask(CK_TASK_GROUP.Score) + nAdd);
	Msg2Player(format("活跃度积分增加%d，总积分为%d", nAdd, CK_TASK_GROUP:GetTask(CK_TASK_GROUP.Score)));
end

--活动介绍
function ck_ActInfo(nIndex)
	local strTitle = 	{
		"活动期间，通过线下活动，即可获得符合自身条件的称号。所有称号有效期为2个月，且在这两个月里亮出称号，角色的全属性增加10点。玩家激活激活称号方可接取任务。百战不殆任务，每日可执行一次。速战速决任务和大富翁任务则在整个活动期间只能完成一次。百战不殆任务可单人完成，也可组队完成，组队做任务奖励效率提高。完成各项任务将会获得经验值和活跃度奖励。累计活跃度可以兑换丰厚奖励。",
		"活跃者组队参与百战不殆任务奖励效率最高。", --和老战友
		"勇往直前任务只在新服出现，在新服中激活武林新秀称号的10级玩家可接取任务。完成这一系列任务，达到90级后，武林新秀玩家才能接取百战不殆，速战速决和大富翁任务。",
	}
	local tbSay = {};
	nIndex = nIndex or 1;
	local Msg = strTitle[nIndex]; 
	if Msg then
		tbSay.msg = CK_NPC_NAME..Msg;
		tbSay.sel = {
			{"\n退出", "nothing"},
		};
		if strTitle[nIndex + 1] then
			tinsert(tbSay.sel, 1, {"下一页", format("#ck_ActInfo(%d)", nIndex + 1)})
		end
		temp_Talk(tbSay);
	end
end

--激活称号
function ck_ActTilte()
	local tSay = {
		"武林新秀/ck_ActTilte_1",
--		"老战友/ck_ActTilte_2",
		"活跃者/ck_ActTilte_3",
		"\n我只是看看而已/nothing",
	}
	local msg = format("激活截止日期为%d/%d/%d", CK_START_ACT[3], CK_START_ACT[2], CK_START_ACT[1]);
	Say(CK_NPC_NAME..format("%s 要激活哪个称号？<color=red>%s<color>", gf_GetPlayerSexName(), msg), getn(tSay), tSay);
end

function ck_CanAct()
	return gf_CheckDuration(CK_START_TIME, CK_START_ACT);		
end

function ck_ActTilte_1()
	if ck_CanAct() ~= 1 then
		Say(CK_NPC_NAME.."激活截止日期已过，不能再激活称号！", 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 1) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "武林新秀"), 0)
		return 0;
	end
--	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 2) ~= 0 then
--		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "老战友"), 0)
--		return 0;
--	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 3) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "活跃者"), 0)
		return 0;
	end
	DebugOutput(GetExtPoint(1), GetExtPoint(2))
	if GetExtPoint(1) == 1 and GetExtPoint(2) ~= 1 then
		if CK_ES_SWITCH == 0 then
			Say(CK_NPC_NAME.."该服务器暂不开放<color=gold>武林新秀<color>称号领取！", 0);
			return 0;
		end
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 1, 1);
		PayExtPoint(1, 1);
		AddTitle(68, 1);
		SetTitleTime(68, 1, GetTime() + (60 * 24 * 3600));
		Msg2Player(format("你获得[%s]称号", "武林新秀"))
		Say(CK_NPC_NAME..format("你获得<color=gold>[%s]<color>称号", "武林新秀"), 0)
		gf_WriteLogEx("CDKEY", "ck_ActTilte", "AddTitle(68, 1)");
		return 1;
	end
	Say(CK_NPC_NAME.."该角色不满足条件，不能领取称号！", 0);
end

function ck_ActTilte_2()
	if ck_CanAct() ~= 1 then
		Say(CK_NPC_NAME.."激活截止日期已过，不能再激活称号！", 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 1) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "武林新秀"), 0)
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 2) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "老战友"), 0)
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 3) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "活跃者"), 0)
		return 0;
	end
	DebugOutput(GetExtPoint(3), GetExtPoint(4))
	if GetExtPoint(3) == 1 and GetExtPoint(4) ~= 1 then
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 2, 1);
		PayExtPoint(3, 1);
		AddTitle(68, 2);
		SetTitleTime(68, 2, GetTime() + (60 * 24 * 3600));
		Msg2Player(format("你获得[%s]称号", "老战友"))
		Say(CK_NPC_NAME..format("你获得<color=gold>[%s]<color>称号", "老战友"), 0)
		gf_WriteLogEx("CDKEY", "ck_ActTilte", "AddTitle(68, 2)");
		return 1;
	end
	Say(CK_NPC_NAME.."该角色不满足条件，不能领取称号！", 0);
end

function ck_ActTilte_3()
	if ck_CanAct() ~= 1 then
		Say(CK_NPC_NAME.."激活截止日期已过，不能再激活称号！", 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 1) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "武林新秀"), 0)
		return 0;
	end
--	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 2) ~= 0 then
--		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "老战友"), 0)
--		return 0;
--	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 3) ~= 0 then
		Say(CK_NPC_NAME..format("你已领取过<color=gold>[%s]<color>称号", "活跃者"), 0)
		return 0;
	end
	DebugOutput(GetExtPoint(5), GetExtPoint(6))
	if GetExtPoint(5) == 1 and GetExtPoint(6) ~= 1 then
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 3, 1);
		PayExtPoint(5, 1);
		AddTitle(68, 3);
		SetTitleTime(68, 3, GetTime() + (60 * 24 * 3600));
		Msg2Player(format("你获得[%s]称号", "活跃者"))
		Say(CK_NPC_NAME..format("你获得<color=gold>[%s]<color>称号", "活跃者"), 0)
		gf_WriteLogEx("CDKEY", "ck_ActTilte", "AddTitle(68, 3)");
		return 1;
	end
	Say(CK_NPC_NAME.."该角色不满足条件，不能领取称号！", 0);
end

--Task1:4-11位勇往直前任务
function ck_TaskForward()
	if CK_ES_SWITCH == 0 then
		Say(CK_NPC_NAME.."该服务器暂不开放<color=red>勇往直前<color>系列任务", 0)
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 1) ~= 1 then
		Say(CK_NPC_NAME..format("只有<color=gold>[%s]<color>才能领取该任务", "武林新秀"), 0)
		return 0;
	end
	if GetLevel() >= 90 or gf_GetPlayerRebornCount() > 0 then
		Say(CK_NPC_NAME.."90级以上或已转生玩家不能参加该任务！",0);
		return 0;
	end
	local tSay = {}
	local tMsg = {"未接取", "未完成", "可交", "已完成"}
	for i = 1, getn(CK_TASK_FORWARD) do
		local nType = 0;
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, i + 3) == 1 then
			nType = 4;
		else
			if tGtTask:check_cur_task(CK_TASK_FORWARD[i][2]) == 0 then
				nType = 1;
			else
				if DirectIsTaskFinish(CK_TASK_FORWARD[i][2]) then
					nType = 3;
				else
					nType = 2;
				end
			end
		end
		if tMsg[nType] then
			tinsert(tSay, CK_TASK_FORWARD[i][1]..format("(%s)/#ck_TaskFoward_do(%d, %d)", tMsg[nType], CK_TASK_FORWARD[i][2], i + 3));
		end
	end
	tinsert(tSay, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."勇往直前任务能快速帮你升级！",getn(tSay), tSay);
end

function ck_TaskFoward_do(nTaskID, nTaskIndex)
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, nTaskIndex) ~= 0 then
		Say(CK_NPC_NAME.."该任务已完成！", 0);
		return 0;
	end
	if nTaskIndex > 4 and CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, nTaskIndex - 1) ~= 1 then
		Say(CK_NPC_NAME.."上一个任务尚未完成", 0);
		return 0;
	end
	if tGtTask:check_cur_task(nTaskID) == 0 then
		DirectGetGTask(nTaskID, 1)
	else
		if DirectIsTaskFinish(nTaskID) then
			if 1 == DirectFinishGTask(nTaskID, 2) then
				CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, nTaskIndex, 1);
				Msg2Player("任务已完成!")
			else
				Msg2Player("任务异常不能完成！");
			end
		else
			Say(CK_NPC_NAME.."任务还未完成！", 0);
		end
	end
end

--勇往直前奖励(对外)
function ck_TaskForward_Award()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	if GetLevel() < 90 and gf_GetPlayerRebornCount() <= 0 then
		SetLevel(90, 1);
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
		Say(CK_NPC_NAME..format("角色等级已升级到%d级，请重新登录游戏！", 90), 1, "重新登录/ExitGame");
	end
end

function ck_CheckCondition()
	local nKind = ck_GetTitleType();
	if nKind == 0 then
		Say(CK_NPC_NAME.."您还没有领取和激活任何称号，不能参加任务！", 0);
		return 0;
	end
	if GetLevel() < 90 and gf_GetPlayerRebornCount() <= 0 then
		Say(CK_NPC_NAME..format("角色等级不足%d级，不能参加任务！", 90), 0);
		return 0;
	end
	return 1;
end

function ck_BaiZhanBuDai()
	if ck_CheckCondition() ~= 1 then
		return 0;
	end
	local tSay = {
		"\n杀怪任务/ck_BZBD_Kill",
		"\n副本任务/ck_BZBD_Raid",
		"\nPVP任务/ck_BZBD_PVP",
		"\n我只是看看而已/nothing",	
	}
	Say(CK_NPC_NAME.."<color=gold>百战不殆<color>任务，每日随机接取，可获得大量经验和活跃度！", getn(tSay), tSay);	
end

--Task3：加成
function ck_BZBD_GetType(nIndex1, nIndex2, nIndex3)
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nIndex3) == 1 then
		return 0.8;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nIndex2) == 1 then
		return 0.8;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nIndex1) == 1 then
		return 0.8;
	end
	return 0;
end

function ck_BZBD_SetType(nIndex1, nIndex2, nIndex3)
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex1, 0)
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex2, 0)
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex3, 0)
	local nSize = gf_GetTeamSize();
	if nSize <= 1 then
		return 0;
	end
	--print("nSize =", nSize)
	local oldPlayerIndex = PlayerIndex;
	local nSelfType = ck_GetTitleType();
	if nSelfType == 0 then
		return 0;
	end
	--print("nSelfType =", nSelfType)
	if nSelfType == 1 then
		for i = 1, nSize do
			PlayerIndex = GetTeamMember(i);
			if PlayerIndex ~= oldPlayerIndex then
				if ck_GetTitleType() == 1 then
					PlayerIndex = oldPlayerIndex
					CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex3, 1)
					return 1;
				end
			end
		end
	end
	if nSelfType == 2 then
		for i = 1, nSize do
			PlayerIndex = GetTeamMember(i);
			if PlayerIndex ~= oldPlayerIndex then
				if ck_GetTitleType() == 3 then
					PlayerIndex = oldPlayerIndex
					CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex2, 1)
					return 1;
				end
			end
		end
	end	
	if nSelfType == 3 then
		for i = 1, nSize do
			PlayerIndex = GetTeamMember(i);
			if PlayerIndex ~= oldPlayerIndex then
				if ck_GetTitleType() == 3 then
					PlayerIndex = oldPlayerIndex
					CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex1, 1)
				end
				if ck_GetTitleType() == 2 then
					PlayerIndex = oldPlayerIndex
					CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nIndex2, 1)
				end
			end
		end
	end
	PlayerIndex = oldPlayerIndex;		
	--print("nIndex1 =", CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nIndex1))
	--print("nIndex2 =", CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nIndex2))
	--print("nIndex3 =", CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nIndex3))	
end

--百战不殆杀怪任务
--Task1:12-16记录,17-21完成
function ck_BZBD_Kill()
	--没有任务就随机分配两个任务
	local nCount = 0;
	local nTaskIndex1 = 0;
	local nTaskIndex2 = 0;
	for i = 12, 16 do
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, i) == 1 then
			if nTaskIndex1 == 0 then
				nTaskIndex1 = i - 11;
			elseif nTaskIndex2 == 0 then
				nTaskIndex2 = i - 11;
			end
			nCount = nCount + 1;
		end
	end
	if nCount ~= 2 then
		for i = 12, 21 do
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, i, 0)
		end
		nCount = ck_GetRandIndex(getn(CK_TASK_BZ_KILL));
		nTaskIndex1 = nCount;
		if 0 ~= mod(nCount + 3, 5) then
			nTaskIndex2 = mod(nCount + 3, 5);
		else
			nTaskIndex2 = 5;
		end
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 11 + nTaskIndex1, 1);
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 11 + nTaskIndex2, 1);
	end
	DebugOutput("nTaskIndex1, nTaskIndex2 =", nTaskIndex1, nTaskIndex2);
	--给对话
	local tSay = {}
	local tMsg = {"未接取", "未完成", "可交", "已完成"}
	local tTask = {nTaskIndex1, nTaskIndex2};
	for i = 1, getn(tTask) do
		local nType = 0;
		DebugOutput("tTask[i] =", tTask[i])
		local nType = 0;
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 16 + tTask[i]) == 1 then
			nType = 4;
		else
			if tGtTask:check_cur_task(CK_TASK_BZ_KILL[tTask[i]][2]) == 0 then
				nType = 1;
			else
				if DirectIsTaskFinish(CK_TASK_BZ_KILL[tTask[i]][2]) then
					nType = 3;
				else
					nType = 2;
				end
			end
		end
		if tMsg[nType] then
			tinsert(tSay, format("\n%s(%s)/#ck_BZBD_Kill_do(%d, %d)", CK_TASK_BZ_KILL[tTask[i]][1], tMsg[nType], CK_TASK_BZ_KILL[tTask[i]][2], 16 + tTask[i]));
		end
	end
	tinsert(tSay, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."百战不殆杀怪任务！",getn(tSay), tSay);
end

function ck_BZBD_Kill_do(nTaskID, nTaskIndex)
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, nTaskIndex) ~= 0 then
		Say(CK_NPC_NAME.."该任务已完成！", 0);
		return 0;
	end
	if tGtTask:check_cur_task(nTaskID) == 0 then
		DirectGetGTask(nTaskID, 1)
	else
		DebugOutput(nTaskID, DirectIsTaskFinish(nTaskID))
		if DirectIsTaskFinish(nTaskID) then
			if 1 == DirectFinishGTask(nTaskID, 2) then
				CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, nTaskIndex, 1);
				Msg2Player("任务已完成!")
			else
				Msg2Player("任务异常不能完成！");
			end
		else
			Say(CK_NPC_NAME.."任务还未完成！", 0);
		end
	end
end

--杀怪任务奖励(对外)
function ck_BZBD_Kill_Award()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	local nParam = ck_BZBD_GetType(8, 9, 10);
	gf_ModifyExp(floor(3000000*(1 + nParam)));
	ck_AddCkScore(floor(10 * (1 + nParam)));
end

--杀怪任务对外接口
--仅设置加成系数
function _ck_BZBD_Kill_Set()
	--print("_ck_BZBD_Kill_Set()")
	gf_TeamOperateEX(function()
		if ck_IsOpen() ~= 1 then
			return 0;
		end
		if ck_GetTitleType() == 0 then
			return 0;
		end
		local nCount = 0;
		local nTaskIndex = 0;
		for i = 12, 16 do 
			--print(i, CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, i))
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, i) ~= 0 then
				nCount = nCount + 1;
				nTaskIndex = i - 11;
			end
		end
		--print("nCount =", nCount)
		if nCount ~= 2 then
			return 0;
		end
		ck_BZBD_SetType(8, 9, 10);
	end);
end

--百战不殆副本任务
--Task1:22-26记录，27-31接取
--Task2:1-5可交，6-10完成
function ck_BZBD_Raid()
	local nCount = 0;
	local nTaskIndex = 0;
	for i = 22, 26 do 
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, i) ~= 0 then
			nCount = nCount + 1;
			nTaskIndex = i - 21;
		end
	end
	if nCount ~= 1 then
		for i = 22, 31 do 
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, i, 0);
		end
		for i = 1, 10 do 
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, i, 0);
		end
		nTaskIndex = ck_GetRandIndex(getn(CK_TASK_BZ_RAID));
--		--关闭太一塔任务-------
--		if nTaskIndex == 5 then
--			nTaskIndex = 3;
--		end
--		-----------------------
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 21 + nTaskIndex, 1);
	end
	local tMsg = {"未接取", "未完成", "可交", "已完成"}
	local nType = 0;
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 26 + nTaskIndex) == 0 then
		nType = 1;
	else
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, nTaskIndex) == 0 then
			nType = 2;
		else
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 5 + nTaskIndex) == 0 then
				nType = 3;
			else
				nType = 4;
			end
		end
	end
	DebugOutput(CK_TASK_BZ_RAID[nTaskIndex], tMsg[nType], nTaskIndex)
	local tSay = {
		format("%s(%s)/#ck_BZBD_Raid_do(%d)",	CK_TASK_BZ_RAID[nTaskIndex], tMsg[nType], nTaskIndex),
		"\n我只是看看而已/nothing",
	}
	Say(CK_NPC_NAME.."百战不殆副本任务！", getn(tSay), tSay);
end

function ck_BZBD_Raid_do(nTaskIndex)
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, 26 + nTaskIndex) == 0 then
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task1, 26 + nTaskIndex, 1);
		Say(CK_NPC_NAME..format("你已经接取了<color=gold>%s<color>任务", CK_TASK_BZ_RAID[nTaskIndex]), 0);
	else
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, nTaskIndex) == 0 then
			Say(CK_NPC_NAME..format("你尚未完成<color=gold>%s<color>任务", CK_TASK_BZ_RAID[nTaskIndex]), 0);
		else
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 5 + nTaskIndex) == 0 then
				CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, 5 + nTaskIndex, 1);
				--给奖励
				ck_BZBD_Raid_Award();
			else
				Say(CK_NPC_NAME..format("你已经完成<color=gold>%s<color>任务", CK_TASK_BZ_RAID[nTaskIndex]), 0);
			end
		end
	end	
end

--百战不殆副本任务奖励
function ck_BZBD_Raid_Award()
	local nParam = ck_BZBD_GetType(11, 12, 13);
	gf_ModifyExp(floor(5000000*(1 + nParam)));
	ck_AddCkScore(floor(15 * (1 + nParam)));
end

--副本任务对外接口
function _ck_BZBD_Raid_Set(nCurIndex)
	gf_TeamOperateEX(function()
		if ck_IsOpen() ~= 1 then
			return 0;
		end
		if ck_GetTitleType() == 0 then
			return 0;
		end
		local nCount = 0;
		local nTaskIndex = 0;
		for i = 22, 26 do 
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task1, i) ~= 0 then
				nCount = nCount + 1;
				nTaskIndex = i - 21;
			end
		end
		if nCount ~= 1 then
			return 0;
		end
		if tonumber(%nCurIndex) ~= nTaskIndex then
			return 0;
		end
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, nTaskIndex) ~= 1 then
			ck_BZBD_SetType(11, 12, 13);
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, nTaskIndex, 1);
			Msg2Player(format("你已完成了%s任务", CK_TASK_BZ_RAID[nTaskIndex]));
		end
	end);
end

--百战不殆PVP任务
--Task2:11-17记录，18-24接取，25-31可交
--Task3:1-7完成
function ck_BZBD_PVP()
	local nCount = 0;
	local nTaskIndex = 0;
	for i = 11, 17 do 
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, i) ~= 0 then
			nCount = nCount + 1;
			nTaskIndex = i - 10;
		end
	end
	if nCount ~= 1 then
		for i = 18, 31 do 
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, i, 0);
		end
		for i = 1, 7 do 
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, i, 0);
		end
		nTaskIndex = random(7);
--		--屏蔽3v3-------------
--		if nTaskIndex == 2 then
--			nTaskIndex = nTaskIndex + 1;
--		end
--		----------------------
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, 10 + nTaskIndex, 1);
	end
	local tMsg = {"未接取", "未完成", "可交", "已完成"}
	local nType = 0;
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 17 + nTaskIndex) == 0 then
		nType = 1;
	else
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 24 + nTaskIndex) == 0 then
			nType = 2;
		else
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nTaskIndex) == 0 then
				nType = 3;
			else
				nType = 4;
			end
		end
	end
	local tSay = {
		format("%s(%s)/#ck_BZBD_PVP_do(%d)",	CK_TASK_BZ_PVP[nTaskIndex], tMsg[nType], nTaskIndex),
		"\n我只是看看而已/nothing",
	}
	Say(CK_NPC_NAME.."百战不殆PVP任务！", getn(tSay), tSay);
end

function ck_BZBD_PVP_do(nTaskIndex)
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 17 + nTaskIndex) == 0 then
		CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, 17 + nTaskIndex, 1);
		Say(CK_NPC_NAME..format("你已经接取了<color=gold>%s<color>", CK_TASK_BZ_PVP[nTaskIndex]), 0);
	else
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 24 + nTaskIndex) == 0 then
			Say(CK_NPC_NAME..format("你尚未完成<color=gold>%s<color>", CK_TASK_BZ_PVP[nTaskIndex]), 0);
		else
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, nTaskIndex) == 0 then
				CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, nTaskIndex, 1);
				--给奖励
				ck_BZBD_PVP_Award();
			else
				Say(CK_NPC_NAME..format("你已经完成<color=gold>%s<color>", CK_TASK_BZ_PVP[nTaskIndex]), 0);
			end
		end
	end	
end

function ck_BZBD_PVP_Award()
	local nParam = 0.8; --ck_BZBD_GetType(14, 15, 16);
	gf_ModifyExp(floor(8000000*(1 + nParam)));
	ck_AddCkScore(floor(20 * (1 + nParam)));
end

--PVP任务对外接口
function _ck_BZBD_PVP_Set(nCurIndex)
	gf_TeamOperateEX(function()
		if ck_IsOpen() ~= 1 then
			return 0;
		end
		if ck_GetTitleType() == 0 then
			return 0;
		end
		local nCount = 0;
		local nTaskIndex = 0;
		for i = 11, 17 do 
			if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, i) ~= 0 then
				nCount = nCount + 1;
				nTaskIndex = i - 10;
			end
		end
		if nCount ~= 1 then
			return 0;
		end
		if tonumber(%nCurIndex) ~= nTaskIndex then
			return 0;
		end
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task2, 24 + nTaskIndex) ~= 1 then
			--ck_BZBD_SetType(14, 15, 16);
			CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task2, 24 + nTaskIndex, 1);
			Msg2Player(format("你已完成了%s任务", CK_TASK_BZ_PVP[nTaskIndex]));
		end
	end);
end

function ck_FastTask()
	if ck_CheckCondition() ~= 1 then
		return 0;
	end
	local tSay = {
		"\n帮会任务/ck_FastTask_Tong",
		"\n指引任务/ck_FastTask_Guide",
		"\n我只是看看而已/nothing",	
	}
	Say(CK_NPC_NAME.."<color=gold>速战速决<color>任务，活动期间只能完成一次，可获得大量经验和活跃度！", getn(tSay), tSay);		
end

function ck_FastTask_Tong()
	local tSay = {
		"\n加入帮会/ck_FastTask_Tong_1",
		"\n再战神兽/ck_FastTask_Tong_2",
		"\n帮派烤肉/ck_FastTask_Tong_3",
		"\n我只是看看而已/nothing",	
	}
	Say(CK_NPC_NAME.."<color=gold>速战速决<color>帮会任务！", getn(tSay), tSay);		
end

--Task3：17位是否完成
function ck_FastTask_Tong_1(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Tong_1(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"加入帮会", "任意加入一个帮会，成为其中一员", "加入帮会，与帮会成员共同努力，让帮会更加强大", 3000000, 100);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 17) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	if IsTongMember() <= 0 then
		Say(CK_NPC_NAME.."不满足条件，不能完成任务！", 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 17, 1);
	--奖励
	gf_ModifyExp(3000000);
	ck_AddCkScore(100);	
	Msg2Player("任务完成！");
end

--Task3：18位是否完成
function ck_FastTask_Tong_2(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Tong_2(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"再战神兽", "上交300点紫光积分", "参加紫光阁打败紫光神兽获得紫光积分", 5000000, 200);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 18) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	--扣紫光积分
	local TSK_POINT = 652;			--记录玩家个人关卡积分
	if GetTask(TSK_POINT) < 300 then
		Say(CK_NPC_NAME..format("您的紫光积分不足<color=red>%d<color>分", 300), 0);
		return 0;
	end
	SetTask(TSK_POINT, GetTask(TSK_POINT) - 300);
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 18, 1);
	--奖励
	gf_ModifyExp(5000000);
	ck_AddCkScore(200);
	Msg2Player("任务完成！");
end

--Task3：19位是否完成
function ck_FastTask_Tong_3(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Tong_3(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"帮派烤肉", "参与帮派烤肉功能上交10个帮派令牌碎片", "帮派烤肉活动乐趣无穷，快去收集帮派令牌碎片吧", 8000000, 300);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 19) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	--扣碎片
	if DelItem(2, 1, 30588, 10) ~= 1 then
		Say(CK_NPC_NAME..format("您背包内的<color=red>%s<color>不足<color=red>%d<color>个", "帮派令牌碎片", 10), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 19, 1);
	--奖励
	gf_ModifyExp(8000000);
	ck_AddCkScore(300);
	Msg2Player("任务完成！");
end

function ck_FastTask_Guide()
	local tSay = {
		"\n月卡/ck_FastTask_Guide_1",
		"\n药丸/ck_FastTask_Guide_2",
		"\n小般若树/ck_FastTask_Guide_3",
		"\n女娲宝盒和幸运星/ck_FastTask_Guide_4",
		"\n我只是看看而已/nothing",	
	}
	Say(CK_NPC_NAME.."<color=gold>速战速决<color>指引任务！", getn(tSay), tSay);	
end

--Task3：20位是否完成
function ck_FastTask_Guide_1(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Guide_1(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"月卡", "激活武林VIP月卡", "激活月卡，玩游戏更轻松", 8000000, 1200);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 20) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	if IsActivatedVipCard() ~= 1 then
		Say(CK_NPC_NAME.."您还没有激活任何月卡，不能完成任务！", 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 20, 1);
	--奖励
	gf_ModifyExp(8000000);
	ck_AddCkScore(1200);
	Msg2Player("任务完成！");
end

--Task3：21,22,23,24位
function ck_FastTask_Guide_2(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Guide_2(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"药丸", "分别使用一次白驹丸，三清丸和六神丸", "使用各类药丸，助你一臂之力", 5000000, 300);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 24) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 21) ~= 1 then
		Say(CK_NPC_NAME..format("您还没有使用过任何<color=red>%s<color>", "白驹丸"), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 22) ~= 1 then
		Say(CK_NPC_NAME..format("您还没有使用过任何<color=red>%s<color>", "三清丸"), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 23) ~= 1 then
		Say(CK_NPC_NAME..format("您还没有使用过任何<color=red>%s<color>", "六神丸"), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 24, 1);
	--奖励
	gf_ModifyExp(5000000);
	ck_AddCkScore(300);
	Msg2Player("任务完成！");
end

--使用白驹丸
function _ck_UseItemBaiJu()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 21, 1);
end

--使用三清丸
function _ck_UseItemSanQing()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 22, 1);
end

--使用六神丸
function _ck_UseItemLiuShen()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 23, 1);
end

--Task3：25,26位
function ck_FastTask_Guide_3(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Guide_3(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"小般若树种", "种1棵小般若树种", "种植小般若树种，赢取经验值奖励", 5000000, 600);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 26) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 25) ~= 1 then
		Say(CK_NPC_NAME..format("您还没有种植过<color=red>%s<color>", "小般若树种"), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 26, 1);
	--奖励
	gf_ModifyExp(5000000);
	ck_AddCkScore(600);
	Msg2Player("任务完成！");
end

--种植小般若树种
function _ck_PlantSmallBanRuo()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 25, 1);	
end

--Task3：27,28,29位
function ck_FastTask_Guide_4(nFlag)
	if not nFlag then
		local tSay = {
			"\n完成任务/#ck_FastTask_Guide_4(1)",
			"\n我只是看看而已/nothing",	
		}
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",
			"女娲宝盒和幸运星", "使用一次女娲宝盒和幸运星", "女娲宝盒和幸运星是宝物，打开看看里面的奖励吧", 5000000, 900);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 29) ~= 0 then
		Say(CK_NPC_NAME.."你已经完成了该任务！", 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 27) ~= 1 then
		Say(CK_NPC_NAME..format("您还没有使用过任何<color=red>%s<color>", "女娲宝盒"), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task3, 28) ~= 1 then
		Say(CK_NPC_NAME..format("您还没有使用过任何<color=red>%s<color>", "幸运星"), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 29, 1);
	--奖励
	gf_ModifyExp(5000000);
	ck_AddCkScore(900);
	Msg2Player("任务完成！");
end

--使用女娲宝盒
function _ck_UseItemNvWa()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 27, 1);	
end

--使用幸运星
function _ck_UseItemLuckyStart()
	if ck_IsOpen() ~= 1 then
		return 0;
	end
	if ck_GetTitleType() == 0 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task3, 28, 1);		
end

function ck_ZiloTask()
	if ck_CheckCondition() ~= 1 then
		return 0;
	end
	local tSay = {
		"\n属性累计任务/ck_ZiloTask_1",
		"\n关卡消费任务/ck_ZiloTask_2",
		"\n我只是看看而已/nothing",	
	}
	Say(CK_NPC_NAME.."<color=gold>大富翁<color>任务，活动期间只能完成一次，可获得大量经验和活跃度！", getn(tSay), tSay);		
end

--Task4：1-7完成情况
function ck_ZiloTask_1(bTalk)
	local nTaskIndex = 0;
	for i = CK_TASK_ZILON_ATRR_BEGIN, getn(CK_TASK_ZILON_ATRR) do
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task4, i) ~= 1 then
			nTaskIndex = i;
			break;
		end
	end
	if nTaskIndex == 0 then
		Say(CK_NPC_NAME..format("恭喜%s<color=gold>属性累计任务<color>已全部完成！", gf_GetPlayerSexName()), 0)
		return 0;
	end
	local tCell = CK_TASK_ZILON_ATRR[nTaskIndex];
	if not tCell then  return 0; end
	if not bTalk then
		local tSay = {
			"\n我要完成/#ck_ZiloTask_1(1)",
			"\n我只是看看而已/nothing",
		}
		local Str = format("角色达到%d转%d级，累计%d声望值，%d师门值，%d军功值", tCell[2][1], tCell[2][2], tCell[2][3], tCell[2][4], tCell[2][5]);
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d",	tCell[1], Str, "努力积累，让自己更强大", tCell[3][1], tCell[3][2]);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if gf_GetPlayerRebornCount() < tCell[2][1] then
		Say(CK_NPC_NAME..format("%s的转生等级不足<color=red>%d<color>级", gf_GetPlayerSexName(), tCell[2][1]), 0);
		return 0;
	end
	if GetLevel() < tCell[2][2] and gf_GetPlayerRebornCount() <= tCell[2][1] then
		Say(CK_NPC_NAME..format("%s的角色等级不足<color=red>%d<color>级", gf_GetPlayerSexName(), tCell[2][2]), 0);
		return 0;
	end
	if GetReputation() < tCell[2][3] then
		Say(CK_NPC_NAME..format("%s的累计声望值不足<color=red>%d<color>点", gf_GetPlayerSexName(), tCell[2][3]), 0);
		return 0;
	end
	if GetTask(336) < tCell[2][4] then
		Say(CK_NPC_NAME..format("%s的累计师门贡献度不足<color=red>%d<color>点", gf_GetPlayerSexName(), tCell[2][4]), 0);
		return 0;
	end
	if abs(GetTask(701)) < tCell[2][5] then
		Say(CK_NPC_NAME..format("%s的累计军功值不足<color=red>%d<color>点", gf_GetPlayerSexName(), tCell[2][5]), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task4, nTaskIndex, 1);
	--奖励
	gf_ModifyExp(tCell[3][1]);
	ck_AddCkScore(tCell[3][2]);
	Msg2Player("任务完成！")
	ck_ZiloTask_1();
end

--Task4：8-12完成情况
function ck_ZiloTask_2(bTalk)
	local nTaskIndex = 0;
	for i = CK_TASK_IB_COST_BEGIN, CK_TASK_IB_COST_BEGIN+getn(CK_TASK_IB_COST)-1 do
		if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Task4, i) ~= 1 then
			nTaskIndex = i - CK_TASK_IB_COST_BEGIN + 1;
			break;
		end
	end
	if nTaskIndex == 0 then
		Say(CK_NPC_NAME..format("恭喜%s<color=gold>消费任务<color>已全部完成！", gf_GetPlayerSexName()), 0)
		return 0;
	end
	local tCell = CK_TASK_IB_COST[nTaskIndex];
	if not tCell then  return 0; end
	if not bTalk then
		local tSay = {
			"\n我要完成/#ck_ZiloTask_2(1)",
			"\n我只是看看而已/nothing",
		}
		local Str = format("在地玄宫，万剑冢，梁山和太一塔任意关卡中累计使用%d个天骄令开箱", tCell[2]);
		local Msg = format("任务名称：<color=gold>%s<color>\n任务条件：\n  %s\n任务说明：\n  %s\n任务奖励：\n  经验值：%d，活跃度：%d", tCell[1], Str, "用天骄令开箱赢取丰厚奖励", tCell[3][1], tCell[3][2]);
		Say(CK_NPC_NAME..Msg, getn(tSay), tSay);
		return 0;
	end
	if ck_GetCostIB() < tCell[2] then
		Say(CK_NPC_NAME..format("%s目前关卡消费天骄令数目不足<color=red>%d<color>个", gf_GetPlayerSexName(), tCell[2]), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Task4, CK_TASK_IB_COST_BEGIN + nTaskIndex - 1, 1);
	--奖励
	gf_ModifyExp(tCell[3][1]);
	ck_AddCkScore(tCell[3][2]);
	Msg2Player("任务完成！")
	ck_ZiloTask_2();
end

--关卡消费天骄令Task5
function ck_GetCostIB()
	return CK_TASK_GROUP:GetTask(CK_TASK_GROUP.Task5);
end

--关卡消费对外接口Task5
function _ck_SetCostIB(nNum)
	if ck_IsOpen() ~= 1 then
		--print("SetCostIB",nNum,"not open")
		return 0;
	end
	if ck_GetTitleType() == 0 then
		--print("SetCostIB",nNum,"no titile")
		return 0;
	end
	nNum = nNum or 1;
	--print("GetCostIB",ck_GetCostIB(),CK_TASK_GROUP.Task5)
	CK_TASK_GROUP:SetTask(CK_TASK_GROUP.Task5, ck_GetCostIB() + tonumber(nNum));
end

function ck_QueryScore()
	Say(CK_NPC_NAME..format("%s当前活跃度积分为<color=gold>%d<color>!", gf_GetPlayerSexName(), ck_GetCkScore()), 0);	
end

function ck_ScoreAward()
	local nScore = ck_GetCkScore();
	local tMsg = {
		[0] = "未完成",
		[1] = "已完成",
	}
	local tSay = {};
	for i = 1, getn(CK_SCROE_AWARD_TABLE) do
		local nType = CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, i);
		tinsert(tSay, format("%d活跃度奖励(%s)/#ck_ScoreAward_func_%d(%d, %d)", CK_SCROE_AWARD_TABLE[i], tMsg[nType], i, nScore, CK_SCROE_AWARD_TABLE[i]));
	end
	tinsert(tSay, "我只是看看而已/nothing");
	Say(CK_NPC_NAME..format("%s当前活跃度积分为<color=gold>%d<color>，请领取奖励吧！", gf_GetPlayerSexName(), nScore), getn(tSay), tSay);
end

function ck_ScoreAward_func_1(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_1(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 1000000, 100, 100, 1000, 10000)..",".."打通武者境界"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 1) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if GetLevel() < 90 then
		Say(CK_NPC_NAME..format("你的等级不足%d级,不能领奖！", 90), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 1, 1);
	gf_Modify("Exp", 1000000);
	gf_Modify("Rep", 100);
	gf_Modify("ShiMen", 100);
	gf_Modify("JunGong", 1000);
	local nLevel = MeridianGetLevel()
	if nLevel < 1 then
		for i = nLevel + 1, 1 do
			MeridianUpdateLevel()
		end
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0)
	else
		gf_Modify("Exp", 1000000);
	end
	gf_Modify("ZhenQi", 10000);
end

function ck_ScoreAward_func_2(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_2(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 2000000, 160, 160, 1400, 0)..",".."1转90级"..",".."耀杨裤（按体型流派）"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 2) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 2, 1);
	gf_Modify("Exp", 2000000);
	gf_Modify("Rep", 160);
	gf_Modify("ShiMen", 160);
	gf_Modify("JunGong", 1400);
	if gf_GetPlayerRebornCount() < 1 then
		gf_SetTaskByte(1538, 1, 1); 			--1转
		SetLevel(90, 1);								  --90级
		Msg2Player("转生等级升级成功！");
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
	else
		gf_Modify("Exp", 2000000);
	end
	ahf_GetYaoYangByRouteBody(VET_YAOYANG_SHOE);
end

function ck_ScoreAward_func_3(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_3(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 3000000, 220, 220, 1800, 15000)..",".."打通武将境界"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 3) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if GetLevel() < 90 then
		Say(CK_NPC_NAME..format("你的等级不足%d级,不能领奖！", 90), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 3, 1);
	gf_Modify("Exp", 3000000);
	gf_Modify("Rep", 220);
	gf_Modify("ShiMen", 220);
	gf_Modify("JunGong", 1800);
	local nLevel = MeridianGetLevel()
	if nLevel < 2 then
		for i = nLevel + 1, 2 do
			MeridianUpdateLevel()
		end
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0)
	else
		gf_Modify("Exp", 1000000);
	end	
	gf_Modify("ZhenQi", 15000);
end

function ck_ScoreAward_func_4(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_4(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 4000000, 280, 280, 2200, 0)..",".."2转90级"..",".."耀杨衣服（按体型流派）"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 4) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 4, 1);
	gf_Modify("Exp", 4000000);
	gf_Modify("Rep", 280);
	gf_Modify("ShiMen", 280);
	gf_Modify("JunGong", 2200);
	if gf_GetPlayerRebornCount() < 2 then
		gf_SetTaskByte(1538, 1, 2); 			--1转
		SetLevel(90, 1);								  --90级
		Msg2Player("转生等级升级成功！");
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
	else
		gf_Modify("Exp", 4000000);
	end
	ahf_GetYaoYangByRouteBody(VET_YAOYANG_CLOTH);
end

function ck_ScoreAward_func_5(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_5(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 5000000, 340, 340, 2600, 25000)..",".."打通武王境界"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 5) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	if GetLevel() < 90 then
		Say(CK_NPC_NAME..format("你的等级不足%d级,不能领奖！", 90), 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 5, 1);
	gf_Modify("Exp", 5000000);
	gf_Modify("Rep", 340);
	gf_Modify("ShiMen", 340);
	gf_Modify("JunGong", 2600);
	local nLevel = MeridianGetLevel()
	if nLevel < 3 then
		for i = nLevel + 1, 3 do
			MeridianUpdateLevel()
		end
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0)
	else
		gf_Modify("Exp", 5000000);
	end	
	gf_Modify("ZhenQi", 25000);
end

function ck_ScoreAward_func_6(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_6(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 6000000, 400, 400, 3000, 0)..",".."3转90级"..",".."耀杨头（按体型流派）"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 6) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 6, 1);
	gf_Modify("Exp", 6000000);
	gf_Modify("Rep", 400);
	gf_Modify("ShiMen", 400);
	gf_Modify("JunGong", 3000);
	if gf_GetPlayerRebornCount() < 3 then
		gf_SetTaskByte(1538, 1, 3); 			--1转
		SetLevel(90, 1);								  --90级
		Msg2Player("转生等级升级成功！");
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
	else
		gf_Modify("Exp", 6000000);
	end
	ahf_GetYaoYangByRouteBody(VET_YAOYANG_CAP);
end

function ck_ScoreAward_func_7(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_7(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 7000000, 460, 460, 3400, 30000)..",".."自选五行徽章"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 7) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	local tDialog = {}
	for i = 1, getn(CK_JS_HUIZHANG) do
		DebugOutput(CK_JS_HUIZHANG[i][1], i)
		tinsert(tDialog, format("%s/#ck_ScoreAward_func_7_Do(%d)", CK_JS_HUIZHANG[i][1], i));
	end
	tinsert(tDialog, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."请选择你需要的类型：", getn(tDialog), tDialog);	
end

function  ck_ScoreAward_func_7_Do(nIndex)
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 7, 1);
	gf_Modify("Exp", 7000000);
	gf_Modify("Rep", 460);
	gf_Modify("ShiMen", 460);
	gf_Modify("JunGong", 3400);
	gf_Modify("ZhenQi", 30000);
	gf_AddItemEx2(CK_JS_HUIZHANG[nIndex][2], CK_JS_HUIZHANG[nIndex][1], "CDKEY", "CDKEY", 0, 1);
end

function ck_ScoreAward_func_8(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_8(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 8000000, 520, 520, 3800, 0)..",".."4转90级"..",".."雷虎精魄*1"..",".."自选五行挂衣"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 8) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	local tDialog = {}
	for i = 1, getn(CK_JS_GUAIYI) do
		tinsert(tDialog, format("%s/#ck_ScoreAward_func_8_Do(%d)", CK_JS_GUAIYI[i][1], i));
	end
	tinsert(tDialog, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."请选择你需要的类型：", getn(tDialog), tDialog);		
end

function ck_ScoreAward_func_8_Do(nIndex)
	if gf_Judge_Room_Weight(2, 100, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 8, 1);
	gf_Modify("Exp", 8000000);
	gf_Modify("Rep", 520);
	gf_Modify("ShiMen", 520);
	gf_Modify("JunGong", 3800);
	if gf_GetPlayerRebornCount() < 4 then
		gf_SetTaskByte(1538, 1, 4); 			--1转
		SetLevel(90, 1);								  --90级
		Msg2Player("转生等级升级成功！");
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
	else
		gf_Modify("Exp", 10000000);
	end
	gf_AddItemEx2({2, 1, 30614, 1, 4}, "雷虎精魄", "CDKEY", "CDKEY", 0, 1);
	gf_AddItemEx2(CK_JS_GUAIYI[nIndex][2], CK_JS_GUAIYI[nIndex][1], "CDKEY", "CDKEY", 0, 1);
end

function ck_ScoreAward_func_9(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_9(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 9000000, 580, 580, 4200, 0)..",".."5转90级"..",".."自选五行鞋子"..",".."雷虎精魄*1"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 9) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	local tDialog = {}
	for i = 1, getn(CK_JS_SHOE) do
		tinsert(tDialog, format("%s/#ck_ScoreAward_func_9_Do(%d)", CK_JS_SHOE[i][1], i));
	end
	tinsert(tDialog, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."请选择你需要的类型：", getn(tDialog), tDialog);	
end

function ck_ScoreAward_func_9_Do(nIndex)
	if gf_Judge_Room_Weight(2, 100, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 9, 1);
	gf_Modify("Exp", 9000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	if gf_GetPlayerRebornCount() < 5 then
		gf_SetTaskByte(1538, 1, 5); 			--1转
		SetLevel(90, 1);								  --90级
		Msg2Player("转生等级升级成功！");
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
	else
		gf_Modify("Exp", 13000000);
	end
	gf_AddItemEx2({2, 1, 30614, 1, 4}, "雷虎精魄", "CDKEY", "CDKEY", 0, 1);
	gf_AddItemEx2(CK_JS_SHOE[nIndex][2], CK_JS_SHOE[nIndex][1], "CDKEY", "CDKEY", 0, 1);
end

function ck_ScoreAward_func_10(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_10(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 10000000, 580, 580, 4200, 0)..",".."耀杨武器（按体型流派）"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 10) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 10, 1);
	gf_Modify("Exp", 10000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	ahf_GetYaoYangWeaponRand(1);
end

function ck_ScoreAward_func_11(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_11(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 11000000, 580, 580, 4200, 0)..",".."战狂头部"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 11) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	ck_ScoreAward_func_11_Do();
end

function ck_ScoreAward_func_11_Do()
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 11, 1);
	gf_Modify("Exp", 11000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	ahf_GetEquipByRouteBody(VET_ZHANKUANG_CAP);
end

function ck_ScoreAward_func_12(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_12(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 12000000, 580, 580, 4200, 0)..",".."自选耀阳2级首饰"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 12) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	local tDialog = {}
	for i = 1, getn(CK_YAOYANG_JIEZI_1) do
		tinsert(tDialog, format("%s/#ck_ScoreAward_func_12_Do(%d)", CK_YAOYANG_JIEZI_1[i][1], i));
	end
	tinsert(tDialog, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."请选择你需要的类型：", getn(tDialog), tDialog);	
end

function ck_ScoreAward_func_12_Do(nIndex)
	if gf_Judge_Room_Weight(2, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 12, 1);
	gf_Modify("Exp", 12000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	gf_AddItemEx2(CK_YAOYANG_JIEZI_1[nIndex][2], CK_YAOYANG_JIEZI_1[nIndex][1], "CDKEY", "CDKEY", 0, 1)
end

function ck_ScoreAward_func_13(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_13(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 18000000, 580, 580, 4200, 0)..",".."5级蕴灵"..",".."自选耀阳2级首饰"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 13) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	local tDialog = {}
	for i = 1, getn(CK_YAOYANG_JIEZI_2) do
		tinsert(tDialog, format("%s/#ck_ScoreAward_func_13_Do(%d)", CK_YAOYANG_JIEZI_2[i][1], i));
	end
	tinsert(tDialog, "\n我只是看看而已/nothing");
	Say(CK_NPC_NAME.."请选择你需要的类型：", getn(tDialog), tDialog);	
end

function ck_ScoreAward_func_13_Do(nIndex)
    if gf_Judge_Room_Weight(2, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 13, 1);
	gf_Modify("Exp", 18000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	--5级蕴灵
	local nRandIndex = random(getn(CK_5_LEVEL_YUNLING));
	gf_AddItemEx2(CK_5_LEVEL_YUNLING[nRandIndex][2], CK_5_LEVEL_YUNLING[nRandIndex][1], "CDKEY", "CDKEY", 0, 1)
	gf_AddItemEx2(CK_YAOYANG_JIEZI_2[nIndex][2], CK_YAOYANG_JIEZI_2[nIndex][1], "CDKEY", "CDKEY", 0, 1)
end

function ck_ScoreAward_func_14(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_14(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 28000000, 580, 580, 4200, 0)..",".."战狂衣服（按体型流派）"..",".."五级蕴灵"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 14) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 14, 1);
	gf_Modify("Exp", 28000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	--战狂衣服
	ahf_GetEquipByRouteBody(VET_ZHANKUANG_CLOTH);
	--5级蕴灵
	local nRandIndex = random(getn(CK_5_LEVEL_YUNLING));
	gf_AddItemEx2(CK_5_LEVEL_YUNLING[nRandIndex][2], CK_5_LEVEL_YUNLING[nRandIndex][1], "CDKEY", "CDKEY", 0, 1)
end

function ck_ScoreAward_func_15(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_15(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 32000000, 580, 580, 4200, 0)..",".."战狂裤子（按体型流派）"..",".."五级蕴灵"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 15) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 15, 1);
	gf_Modify("Exp", 32000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	--战狂裤子
	ahf_GetEquipByRouteBody(VET_ZHANKUANG_SHOE);
	--5级蕴灵
	local nRandIndex = random(getn(CK_5_LEVEL_YUNLING));
	gf_AddItemEx2(CK_5_LEVEL_YUNLING[nRandIndex][2], CK_5_LEVEL_YUNLING[nRandIndex][1], "CDKEY", "CDKEY", 0, 1)
end

function ck_ScoreAward_func_16(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_16(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 36000000, 580, 580, 4200, 0)..",".."6转90级"..",".."五级蕴灵"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 16) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 16, 1);
	gf_Modify("Exp", 36000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	if gf_GetPlayerRebornCount() < 6 then
		gf_SetTaskByte(1538, 1, 5); 			--1转
		PlayerReborn(1,random(1,4))
		SetLevel(90, 1);								  --90级
		Msg2Player("转生等级升级成功！");
		PlaySound("\\sound\\sound_i016.wav");
		SetCurrentNpcSFX(PIdx2NpcIdx(),905,0,0);
	else
		gf_Modify("Exp", 30000000);
	end
	--5级蕴灵
	local nRandIndex = random(getn(CK_5_LEVEL_YUNLING));
	gf_AddItemEx2(CK_5_LEVEL_YUNLING[nRandIndex][2], CK_5_LEVEL_YUNLING[nRandIndex][1], "CDKEY", "CDKEY", 0, 1)
end

function ck_ScoreAward_func_17(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_17(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 40000000, 580, 580, 4200, 0)..",".."战狂武器（按体型流派）"..",".."中级灵兽蛋"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 17) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 17, 1);
	gf_Modify("Exp", 40000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	gf_AddItemEx2({2, 1, 30727, 1, 4}, "中级灵兽蛋", "CDKEY", "CDKEY", 0, 1)
	ahf_GetEquipByRouteBody(VET_ZHANKUANG_WEAPON)
end

function ck_ScoreAward_func_18(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_18(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 44000000, 580, 580, 4200, 0)..",".."随机4~6级宝石"..",".."高级灵兽蛋"..",".."6级蕴灵"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 18) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(2, 200, " ") ~= 1 then
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 18, 1);
	gf_Modify("Exp", 44000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	gf_AddItemEx2({2, 1, 30728, 1, 4}, "高级灵兽蛋", "CDKEY", "CDKEY", 0, 1)
	ck_GiveRandGem456()
	--6级蕴灵
	local nRandIndex = random(getn(CK_6_LEVEL_YUNLING));
	gf_AddItemEx2(CK_6_LEVEL_YUNLING[nRandIndex][2], CK_6_LEVEL_YUNLING[nRandIndex][1], "CDKEY", "CDKEY", 0, 1)
end

function ck_ScoreAward_func_19(nCurScore, nNeedScore, bTalk)
	if not bTalk then
		local tSay = {
			format("\n领取奖励/#ck_ScoreAward_func_19(%d,%d,1)", nCurScore, nNeedScore),
			"\n我只是看看而已/nothing",
		}
		local Msg = format("经验%s，声望%d，师门贡献度%d，军功值%d，真气值%d", 48000000, 580, 580, 4200, 0)..",".."[任务达人]称号"..",".."6级蕴灵"
		Say(CK_NPC_NAME..format("当前可领取奖励：\n   <color=green>%s<color>\n<color=red>不能再给与的奖励将用一定数量的经验替代<color>", Msg), getn(tSay), tSay);
		return 0;
	end
	if tonumber(nCurScore) < tonumber(nNeedScore) then
		Say(CK_NPC_NAME..format("活跃度积分没有达到<color=red>%d<color>,不能领取奖励！", tonumber(nNeedScore)), 0);
		return 0;
	end
	if CK_TASK_GROUP:GetTaskBit(CK_TASK_GROUP.Award, 19) ~= 0 then
		Say(CK_NPC_NAME.."你已经领取过该奖励了！", 0);
		return 0;
	end
	CK_TASK_GROUP:SetTaskBit(CK_TASK_GROUP.Award, 19, 1);
	gf_Modify("Exp", 48000000);
	gf_Modify("Rep", 580);
	gf_Modify("ShiMen", 580);
	gf_Modify("JunGong", 4200);
	--6级蕴灵
	local nRandIndex = random(getn(CK_6_LEVEL_YUNLING));
	gf_AddItemEx2(CK_6_LEVEL_YUNLING[nRandIndex][2], CK_6_LEVEL_YUNLING[nRandIndex][1], "CDKEY", "CDKEY", 0, 1)
	AddTitle(68, 4);
	SetTitleTime(68, 4, GetTime() + 60 * 24 * 3600);
	Msg2Player(format("你获得[%s]称号", "任务达人"))
end
