Include("\\script\\function\\honor_tong\\ht_head.lua")
Include("\\script\\lib\\talktmp.lua")

HTN_DIALOG = {
	"荣誉帮派介绍/htn_Infomation",
	"登记参加荣誉帮派/htn_SignTong",
	"奉献建设帮派/htn_BuildTong",
	"领取排名奖励/htn_RankAward",
	"查看帮派奉献值及排名/htn_TongRank",
	--"攻城资格赛登记/htn_Gongcheng",
};

HTN_TITLE = "为了帮派的荣誉，小伙伴们都行动起来吧！";

function htn_Infomation()
	local tSay = {
		"参与条件/htn_Info_JoinCondition",
		"如何奉献建设帮派/htn_Info_BuildTong",
		"如何获取材料/htn_Info_GetMaterial",
		"帮派排名奖励/htn_Info_TongRank",
		"我只是看看而已/nothing",
	}
	Say(HT_NPC..format("%s想了解哪些方面的信息？", gf_GetPlayerSexName()), getn(tSay), tSay);
end

function htn_Info_JoinCondition()
	local tbBody = "\n	1,达90级以上的玩家，55级的技能已满级;\n	2,角色要加入帮派7天以上才能参加;\n	3,需要消耗[帮派令牌碎片]*1、[道具XU]*1;\n	4,需要帮主激活荣誉帮派功能。";
	local tbSay = {};
	tbSay.msg = HT_NPC..tbBody;
	tbSay.sel = {
		{"\n返回", "htn_Infomation"},
		{"退出","nothing"},
	};
	temp_Talk(tbSay);
end

function htn_Info_BuildTong()
	local tbBody = "帮派成员可以向活动大使上交[帮派令牌碎片]*1、[道具XU]*1，每一次奉献建设帮派后将获得经验和道具奖励，并且帮派增加1点奉献值，奉献值的高低决定帮派的排名，排名有额外的奖励。";
	local tbSay = {};
	tbSay.msg = HT_NPC..tbBody;
	tbSay.sel = {
		{"\n返回", "htn_Infomation"},
		{"退出","nothing"},
	};
	temp_Talk(tbSay);
end

function htn_Info_GetMaterial()
	local tDialog = {
		"参加帮派宴席获得的帮派令牌碎片/htn_Info_GetMaterial",
		"开启大战金宝箱（世界BOSS）100%获得05帮派令牌碎片/htn_Info_GetMaterial",
		"开启大战宝盒（世界BOSS）100%获得01帮派令牌碎片/htn_Info_GetMaterial",
		"太一塔关卡50%获得01帮派令牌碎片/htn_Info_GetMaterial",
		"英雄太一塔关卡100%获得01帮派令牌碎片/htn_Info_GetMaterial",
		"万剑冢关卡20%获得01帮派令牌碎片/htn_Info_GetMaterial",
		"地玄宫关卡25%获得01帮派令牌碎片/htn_Info_GetMaterial",
		"梁山伯关卡25%获得01帮派令牌碎片/htn_Info_GetMaterial",
		"紫光阁闯关获得02帮派令牌碎片/htn_Info_GetMaterial",
		"返回/htn_Infomation",
		"退出/nothing",
	}
	Say(HT_NPC.."以下是帮派令牌碎片的获取途径：", getn(tDialog), tDialog);
end

function htn_Info_TongRank()
	local tbBody = format("帮派奉献值达到%d积分的帮派将获得大量经验和武林召集令，武林召集令使用后召唤东方不败BOSS，击败BOSS获得帮派金宝箱，开启宝箱将获得极品奖励，此外排名第一的帮派将获得<color=gold>荣誉帮主<color>和<color=gold>荣誉帮派<color>称号", HT_TONG_VALUE_LIMIT);
	local tbSay = {};
	tbSay.msg = HT_NPC..tbBody;
	tbSay.sel = {
		{"\n返回", "htn_Infomation"},
		{"退出","nothing"},
	};
	temp_Talk(tbSay);
end

function htn_SignTong()
	local tSay = {
		"我要登记荣誉帮派/htn_SignTong_Deal",
		"我只是看看而已/nothing",
	}
	Say(HT_NPC..format("只有帮主才能登记荣誉帮派活动，%s要确定要登记吗？", gf_GetPlayerSexName()), getn(tSay), tSay);
end

function htn_SignTong_Deal()
	if ht_CheckCondition() ~= 1 then
		return 0;
	end
	if ht_GetTimeFunc() ~= 1 then
		Say(HT_NPC.."现在不是登记时间，请下周再来！", 0);
		return 0;
	end
	if GetTongDuty() ~= 1 then
		Say(HT_NPC..format("%s不是帮主，不能登记荣誉帮派活动！", gf_GetPlayerSexName()), 0);
		return 0;
	end
	if GetCash() < HT_COST_GOLD*10000 then
		Say(HT_NPC..format("背包内金子不足%d金", HT_COST_GOLD), 0)
		return 0;
	end
	return ht_SignTong();
end

function htn_BuildTong()
	if ht_CheckCondition() ~= 1 then
		return 0;
	end
	if ht_GetTimeFunc() ~= 1 then
		Say(HT_NPC.."现在不是上交时间，请下周再来！", 0);
		return 0;
	end
	ht_buildTong_AskforClient();
end

function htn_TongRank()
	if ht_CheckCondition() ~= 1 then
		return 0;
	end
	ht_TongRank_Show();
end

function htn_RankAward()
	if ht_CheckCondition() ~= 1 then
		return 0;
	end
	if ht_GetTimeFunc() == 1 then
		Say(HT_NPC.."现在是奉献帮派建设时间，不能领取帮派排名奖励！", 0);
		return 0;
	end
	if ht_GetTimeFunc() == 2 then
		Say(HT_NPC.."系统整理帮派奉献值的排行榜，请稍后再来！", 0);
		return 0;
	end
	if gf_Judge_Room_Weight(1, 10) ~= 1 then
		return 0;
	end
	ht_GetRankAward();
end

--function htn_Gongcheng()
--	local tSay = {
--		"我要立刻登记/ht_SignGongcheng",
--		"我只是看看而已/nothing",
--	}
--	Say(HT_NPC.."只有在此成功登记后才能参加下周五成都擂台老板举行的攻城资格赛,您需要登记吗？", getn(tSay), tSay);
--end