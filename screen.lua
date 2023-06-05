screen = {}
--[[
0000 ip
0020 port
0100 版本号
0120 设备编号
0140 未校验版本号
0160 未校准设备编号
0220 二维码
0420 电压 num
0430 电流 num
0440 电量 num
0450 已充电时长 
0470 功率 num
0600 订单号
0650 开始时间
0680 结束时间
06b0 总充电时长
06f0 充电金额 num
0700 暂无
0720 暂无
-- 0930 充电时长
-- 0950 充电电量
0a00 桩号设置
0a10 0a20 0a30 0a40 ip 设置
0a50 端口设置
0ab0 set ok tip
0a60 电压设置
0a70 电流设置
0a80 功率设置
]]
function Screen_Frame_Send(dat)
    local head = '5aa5'
    local datln = '00'
    local datln = string.format("%02X", string.len(dat)//2)
    local ret = head .. datln .. dat
    return string.fromHex(ret)
end

return screen