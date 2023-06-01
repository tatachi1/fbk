--[[
起始标志    数据长度    序列号域    加密标志    桢类型标志    消息体     桢校验域
1字节       1字节       2字节       1字节       1字节       N字节    2字节
68
]]
datafix = {}

-- 计算CRC16 Modbus
function Crc16_Modbus(hex_string)
    local crc = 0xFFFF
    local poly = 0xA001

    for i = 1, #hex_string, 2 do
        local byte = tonumber(hex_string:sub(i, i + 1), 16)

        crc = crc ~ byte

        for j = 1, 8 do
            local lsb = crc & 0x0001

            crc = crc >> 1

            if lsb == 1 then
                crc = crc ~ poly
            end
        end
    end

    return string.format("%04X", crc)
end

function Frame_Send(sernum, crypto, frametype, dat)
    local head = '68'
    local datln = '00'
    local sernum = '0000' --string.format('%04X', sernum)
    local cryptof = '00'
    --local crypto = '00'  --除0外都加密
    local crc16 = 'ffff'
    local crlf = '0d0a'

    local datln = string.format("%02X", string.len(dat) // 2 + 4)
    local bfcrc16 = sernum .. cryptof .. frametype .. dat

    local crc = Crc16_Modbus(bfcrc16)

    local afcrc = head .. datln .. bfcrc16 .. crc
    -- local afcrc = head .. datln .. bfcrc16 .. '0000'

    return string.fromHex(afcrc)
end

function Frame_Recv(data)
    local hexStr, len = string.toHex(data)
    local databf = hexStr:gsub('%s', '')
    local i, j, dataf = databf:find('(68.-0D0A)')
    -- local sci = ''
    --if dataf ~= nil then
    local sci = databf:gsub(dataf, '')
    --end
    local head = dataf:sub(1, 2)
    local datln = dataf:sub(3, 4)
    local sernum = dataf:sub(5, 8)
    local cryptof = dataf:sub(9, 10)
    local frametype = dataf:sub(11, 12)
    local dat = ''
    local crcmodbus = ''
    local tail = dataf:sub(-4, -1)

    if tail:lower() == '0d0a' then
        crcmodbus = dataf:sub(-8, -5)
        dat = dataf:sub(13, -9)
    else
        crcmodbus = dataf:sub(-4, -1)
        dat = dataf:sub(13, -5)
    end

    local len = string.len(dat) // 2 + 4
    local crc16_T = Crc16_Modbus(sernum .. cryptof .. frametype .. dat)
    local datln_num = tonumber(datln, 16)
    local ret = {
        head = head,
        datln = datln,
        sernum = sernum,
        cryptof = cryptof,
        frametype = frametype,
        dat = dat,
        crcmodbus = crcmodbus,
        hexStr = hexStr, --带空格
        dataf = dataf,   --去空格
    }

    local head_error = false
    local datln_error = false
    local crc16_error = false
    local error = false
    if '68' == head then
        if len == datln_num then
            if crc16_T == crcmodbus then
                --if 1 then
                return ret, error, sci
            else
                --log.error('校验错误', '应为:', crc16_T, '实为:', crcmodbus)
                log.error('crc16_error', 'should be:', crc16_T, 'but:', crcmodbus, hexStr)
                crc16_error = true
            end
        else
            --log.error('帧长错误', '应为:', len, '实为:', datln)
            log.error('datln_error', 'should be:', len, 'but:', datln_num, hexStr)
            datln_error = true
        end
    else
        --log.error('帧头错误', '应为:', '68', '实为:', head)
        log.error('head_error', 'should be:', '68', 'but:', head, hexStr)
        head_error = true
    end
    if head_error or datln_error or crc16_error then
        error = true
    end
    return ret, error, sci
end

function Send(data, txqueue, taskName)
    local hexStr, len = string.fromHex(data)
    table.insert(txqueue, hexStr)
    sys_send(taskName, socket.EVENT, 0)
end

function Model_Fix(modeldata)
    --1 尖 2 峰 3 平 4 谷
    local pile_id = modeldata:sub(1, 14)
    local feemodel_id = modeldata:sub(15, 18)
    local fee_1 = modeldata:sub(19, 26)
    local serfee_1 = modeldata:sub(27, 34)
    local fee_2 = modeldata:sub(35, 42)
    local serfee_2 = modeldata:sub(43, 50)
    local fee_3 = modeldata:sub(51, 58)
    local serfee_3 = modeldata:sub(59, 66)
    local fee_4 = modeldata:sub(67, 74)
    local serfee_4 = modeldata:sub(75, 82)
    local loss_rat = modeldata:sub(83, 84)
    local time = {
        [1]  = modeldata:sub(85, 86),
        [2]  = modeldata:sub(87, 88),
        [3]  = modeldata:sub(89, 90),
        [4]  = modeldata:sub(91, 92),
        [5]  = modeldata:sub(93, 94),
        [6]  = modeldata:sub(95, 96),
        [7]  = modeldata:sub(97, 98),
        [8]  = modeldata:sub(99, 100),
        [9]  = modeldata:sub(101, 102),
        [10] = modeldata:sub(103, 104),
        [11] = modeldata:sub(105, 106),
        [12] = modeldata:sub(107, 108),
        [13] = modeldata:sub(109, 110),
        [14] = modeldata:sub(111, 112),
        [15] = modeldata:sub(113, 114),
        [16] = modeldata:sub(115, 116),
        [17] = modeldata:sub(117, 118),
        [18] = modeldata:sub(119, 120),
        [19] = modeldata:sub(121, 122),
        [20] = modeldata:sub(123, 124),
        [21] = modeldata:sub(125, 126),
        [22] = modeldata:sub(127, 128),
        [23] = modeldata:sub(129, 130),
        [24] = modeldata:sub(131, 132),
        [25] = modeldata:sub(133, 134),
        [26] = modeldata:sub(135, 136),
        [27] = modeldata:sub(137, 138),
        [28] = modeldata:sub(139, 140),
        [29] = modeldata:sub(141, 142),
        [30] = modeldata:sub(143, 144),
        [31] = modeldata:sub(145, 146),
        [32] = modeldata:sub(147, 148),
        [33] = modeldata:sub(149, 150),
        [34] = modeldata:sub(151, 152),
        [35] = modeldata:sub(153, 154),
        [36] = modeldata:sub(155, 156),
        [37] = modeldata:sub(157, 158),
        [38] = modeldata:sub(159, 160),
        [39] = modeldata:sub(161, 162),
        [40] = modeldata:sub(163, 164),
        [41] = modeldata:sub(165, 166),
        [42] = modeldata:sub(167, 168),
        [43] = modeldata:sub(169, 170),
        [44] = modeldata:sub(171, 172),
        [45] = modeldata:sub(173, 174),
        [46] = modeldata:sub(175, 176),
        [47] = modeldata:sub(177, 178),
        [48] = modeldata:sub(179, 180),
    }
    -- local time={}
    -- local countj =1
    -- for i =85,179 do
    --     time[i] = modeldata:sub(i, i +1)
    --     countj = countj + 1
    -- end
    ret = {
        pile_id = pile_id,
        feemodel_id = feemodel_id,

        fee_1 = fee_1,
        serfee_1 = serfee_1,
        fee_1_sum = Dec_Reserve_to_Hex(Hex_Reserve_to_Dec(fee_1,5)+Hex_Reserve_to_Dec(serfee_1,5),5),
        fee_2 = fee_2,
        serfee_2 = serfee_2,
        fee_2_sum = Dec_Reserve_to_Hex(Hex_Reserve_to_Dec(fee_2,5)+Hex_Reserve_to_Dec(serfee_2,5),5),
        fee_3 = fee_3,
        serfee_3 = serfee_3,
        fee_3_sum = Dec_Reserve_to_Hex(Hex_Reserve_to_Dec(fee_3,5)+Hex_Reserve_to_Dec(serfee_3,5),5),
        fee_4 = fee_4,
        serfee_4 = serfee_4,
        fee_4_sum = Dec_Reserve_to_Hex(Hex_Reserve_to_Dec(fee_4,5)+Hex_Reserve_to_Dec(serfee_4,5),5),
        loss_rat = loss_rat,
        time = time
    }
    return ret
end

function Model_Log(model)
    log.info('model', '桩id            ', model.pile_id)
    log.info('model', 'feemodel_id     ', model.feemodel_id)
    log.info('model', 'fee_1      ', '尖', Hex_Reserve_to_Dec(model.fee_1,5))
    log.info('model', 'serfee_1   ', '尖', Hex_Reserve_to_Dec(model.serfee_1,5))
    log.info('model', 'fee_1_sum   ', '尖', Hex_Reserve_to_Dec(model.fee_1_sum,5))
    log.info('model', 'fee_2      ', '峰', Hex_Reserve_to_Dec(model.fee_2,5))
    log.info('model', 'serfee_2   ', '峰', Hex_Reserve_to_Dec(model.serfee_2,5))
    log.info('model', 'fee_2_sum   ', '峰', Hex_Reserve_to_Dec(model.fee_2_sum,5))
    log.info('model', 'fee_3      ', '平', Hex_Reserve_to_Dec(model.fee_3,5))
    log.info('model', 'serfee_3   ', '平', Hex_Reserve_to_Dec(model.serfee_3,5))
    log.info('model', 'fee_3_sum   ', '平', Hex_Reserve_to_Dec(model.fee_3_sum,5))
    log.info('model', 'fee_4      ', '谷', Hex_Reserve_to_Dec(model.fee_4,5))
    log.info('model', 'serfee_4   ', '谷', Hex_Reserve_to_Dec(model.serfee_4,5))
    log.info('model', 'fee_4_sum   ', '谷', Hex_Reserve_to_Dec(model.fee_4_sum,5))
    local timeArray = {}
    local hour, min = 0, 0
    for i = 1, 48 do
        timeArray[i] = string.format('%02d:%02d', hour, min)
        min = min + 30
        if min >= 60 then
            hour = hour + 1
            min = 0
        end
    end
    timeArray[49] = '00:00'
    timeArray[50] = 'end'
    -- for i in pairs(timeArray) do
    -- print(i,timeArray[i])
    -- end
    local stringArray = {
        ['00'] = '尖',
        ['01'] = '峰',
        ['02'] = '平',
        ['03'] = '谷',
    }
    local time = model.time
    -- for i in pairs(time) do
    --     print (i)
    -- end
    local forecount = 1
    local count = 1
    for i = 1, 48 do
        if time[i] == time[i + 1] then
            count = count + 1
        else
            count = count + 1
            log.info('halftime', timeArray[forecount] .. '-' .. timeArray[count], stringArray[time[i]])
            --log.info('halftime', forecount .. '-' .. count, stringArray[time[i]])
            --print(forecount,count)
            forecount = count
        end

        -- log.info('halfhourfee',string.format('%02d:00 - %02d:30', i//2,i//2),time[i+1])
    end
end

-- 获取当前时间并判断所属电费档位
function GetElectricityRate(electricityRates)
    local currentTime = os.date("*t") -- 获取当前时间

    local hour = currentTime.hour
    local minute = currentTime.min

    -- 将时间转换为以半个小时为单位的分钟数
    local totalMinutes = hour * 60 + minute
    print(totalMinutes)
    local halfHour = math.floor(totalMinutes / 30)
    print(halfHour)
    -- 根据半个小时的区间获取电费档位
    local electricityRate = electricityRates[halfHour + 1]
    local datatime = string.format('%s -- %s', halfHour / 2, halfHour / 2 + 0.5)
    return currentTime, datatime, electricityRate
end
-- 小端转大端 16 to 10
function Hex_Reserve_to_Dec(hex,num)
    --reverse
    local data_new = ''
    for i = 1, #hex, 2 do
        data_new = hex:sub(i, i + 1) .. data_new
    end
    --trans
    local dec = tonumber(data_new, 16)
    return tostring(dec / 10^num)
end
-- 大端转小端 10 to 16
function Dec_Reserve_to_Hex(Dec, num)
    --trans
    local hex = math.modf(Dec * 10 ^ num)
    local hexstr = string.format('%08x',hex)
    --reverse
    local data_new = ''
    for i = 1, #hexstr, 2 do
        data_new = hexstr:sub(i, i + 1) .. data_new
    end
    return data_new
end
-- 解析CP56time2a格式数据
function ParseCP56time2a(hexString)
    -- 解析字段
    local msec = tonumber(hexString:sub(3, 4) .. hexString:sub(1, 2), 16)
    local min = tonumber(hexString:sub(5, 6), 16) % 60
    local hour = tonumber(hexString:sub(7, 8), 16) % 24
    local mday = tonumber(hexString:sub(9, 10), 16) % 32
    local wday = (tonumber(hexString:sub(9, 10), 16) >> 5)
    local month = tonumber(hexString:sub(11, 12), 16)
    local year = tonumber(hexString:sub(13, 14), 16) + 2000

    -- 构造结果表
    local result = {
        msec = msec % 1000,
        sec = msec // 1000,
        min = min,
        hour = hour,
        mday = mday,
        wday = wday,
        month = month,
        year = year
    }
    local formattime = string.format("%02d:%02d:%02d.%03d %04d-%02d-%02d",
        result.hour, result.min, result.sec, result.msec, result.year, result.month, result.mday)
    --     数组 ，  格式时间
    return result, formattime
end

--[[
    local time = {
        year = ,
        month =,
        mday =,
        hour =,
        min =,
        sec =,
        msec =,
    }
]]
function ConvertToCP56Time2a(result)
    -- 分解
    local year = result.year
    local month = result.month
    local day = result.mday
    local hour = result.hour
    local minute = result.min
    local second = result.sec
    local millisecond = result.msec
    -- 计算毫秒值
    local msec = millisecond + second * 1000

    -- 构造CP56Time2a字段
    local cp56time2a = string.format("%02X%02X%02X%02X%02X%02X",
        msec % 256, math.floor(msec / 256) % 256, minute, hour, day, month)

    -- 如果年份为两位数，则减去2000并转为十六进制
    if year >= 2000 and year <= 2099 then
        cp56time2a = cp56time2a .. string.format("%02X", year - 2000)
    elseif year >= 1900 and year <= 1999 then
        cp56time2a = cp56time2a .. string.format("%02X", year - 1900)
    else
        -- 年份超出范围
        return 'outrange'
    end

    return cp56time2a
end

-- 示例数据，十六进制字符串表示
-- local data = "E0AB380D130517"

-- -- 解析CP56time2a格式数据
-- local result ,timeform= ParseCP56time2a(data)
-- print(timeform)
-- -- 输出解析结果
-- for key, value in pairs(result) do
--     print(key, value)
-- end
function ConvertToCP56Time2a_Osdate()
    local t = os.date('*t')
    -- 分解
    local year = t.year
    local month = t.month
    local day = t.day
    local hour = t.hour
    local minute = t.min
    local second = t.sec
    local millisecond = 0
    -- 计算毫秒值
    local msec = millisecond + second * 1000

    -- 构造CP56Time2a字段
    local cp56time2a = string.format("%02X%02X%02X%02X%02X%02X",
        msec % 256, math.floor(msec / 256) % 256, minute, hour, day, month)

    -- 如果年份为两位数，则减去2000并转为十六进制
    if year >= 2000 and year <= 2099 then
        cp56time2a = cp56time2a .. string.format("%02X", year - 2000)
    elseif year >= 1900 and year <= 1999 then
        cp56time2a = cp56time2a .. string.format("%02X", year - 1900)
    else
        -- 年份超出范围
        return 'outrange'
    end

    return cp56time2a
end

-- print(os.date())
-- t = ConvertToCP56Time2a_Osdate(os.date())
-- print(t)
-- print(ParseCP56time2a(t))
-- print(os.date())
function Bill_Detail_Link(gun_1, Gfeemodel)
    local ret = gun_1.ordernumber .. gun_1.pile_id .. gun_1.id .. gun_1.charge_onTime .. gun_1.charge_offTime ..
        Gfeemodel.fee_1_sum .. '00000000' .. '00000000' .. '00000000' .. -- 尖单价 尖电量 计损尖电量 尖金额
        Gfeemodel.fee_2_sum .. '00000000' .. '00000000' .. '00000000' ..
        Gfeemodel.fee_3_sum .. '00000000' .. '00000000' .. '00000000' ..
        Gfeemodel.fee_4_sum .. '00000000' .. '00000000' .. '00000000' ..
        '00000000' .. '00000000' ..           --电表总起值 电表总止值
        '00000000' .. '00000000' .. '00000000' .. -- 总电量 计损总电量 消费金额
        '2000000000000000000000000000000000' .. --电动汽车唯一标识
        '01' .. gun_1.charge_offTime .. '40' .. -- 交易标识 交易时间 停止原因
        '0000000000000000'                    -- 物理卡号
    return ret
end
-- 上传实时监测数据连接
function Up_Data_Link(gun_1)
    local ret = gun_1.ordernumber .. gun_1.pile_id .. gun_1.id .. gun_1.state .. gun_1.toHome ..
        gun_1.linkBattery .. gun_1.outVol .. gun_1.outCurr .. gun_1.gunTemp .. gun_1.gunCode ..
        gun_1.SOC .. gun_1.batteryTemp .. gun_1.chargeTimeSum ..
        gun_1.remainTime .. gun_1.chargeDegree .. gun_1.chargeLossDegree .. gun_1.money .. gun_1.error
    return ret
end

return datafix
