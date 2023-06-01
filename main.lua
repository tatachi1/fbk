-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "socket2"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- 一定要添加sys.lua !!!!
sys = require("sys")
sysplus = require("sysplus")
libnet = require("libnet")
datafix = require("datafix")
--pack =require ("pack")
--=============================================================
-- 测试网站 https://netlab.luatos.com/ 点击 打开TCP 获取测试端口号
-- 要按实际情况修改

--default
local host = "112.125.89.8" -- 服务器ip或者域名, 都可以的
local port = 34328          -- 服务器端口号
-- --测试
local host = "47.99.64.36"  -- 服务器ip或者域名, 都可以的
local port = 9999           -- 服务器端口号
--正式
local host = "47.97.37.117" -- 服务器ip或者域名, 都可以的
local port = 9999           -- 服务器端口号

local is_udp = false        -- 如果是UDP, 要改成true, false就是TCP
local is_tls = false        -- 加密与否, 要看服务器的实际情况
--=============================================================
--myval

local sernum = 0
local crytoflag = 0
--直流
-- local pile_id = '10002302130001'
-- local pile_type = '00'
-- local pile_number = '02'
--交流
local pile_id = '10002301070009'
local pile_type = '01'
local pile_number = '01'

sys.taskInit(function()
    sys.wait(1000)
    mobile.simid(2, true) --优先用SIM0
    simid = mobile.iccid()
    if simid then
        log.info("iccid", mobile.iccid())
    else
        log.info("iccid", mobile.iccid(), '找不到simid改用默认')
        simid = '898602D5112157009912'
    end
    -- simid = '898602D5112157009912'
    sys.publish('simidready')
end)

local Operators = '00'                  --00移动02电信03联通04其他
local agreementV = '0e'                 -- 协议版本
local procedureV = '56342E312E35300000' --程序版本

--[[
    Bit位表示（0否1是），低位到高位顺序
    Bit1：急停按钮动作故障；
    Bit2：无可用整流模块；
    Bit3：出风口温度过高；
    Bit4：交流防雷故障；
    Bit5：交直流模块 DC20 通信中断；
    Bit6：绝缘检测模块 FC08 通信中断；
    Bit7：电度表通信中断；
    Bit8：读卡器通信中断；
    Bit9：RC10 通信中断；
    Bit10：风扇调速板故障；
    Bit11：直流熔断器故障；
    Bit12：高压接触器故障；
    Bit13：门打开；
    Bit14：连接中断；
]]

--gun_2
-- local gun_2 = '02'
-- local gun_1state = ''

local ReconnectReq = 0
local ReconnectVic = -1
-- fskv 初始化
sys.taskInit(function()
    fskv.init()

    Gfeemodel = fskv.get('Gfeemodel')
    if Gfeemodel == nil then
        fskv.set("Gfeemodel", {
            -- pile_id = '10002302130001', --桩号
            feemodel_id = '00000000',   --模型号
            fee_1 = '00000000',         --尖
            serfee_1 = '00000000',      --尖
            fee_1_sum = '00000000',     --尖sum
            fee_2 = '00000000',         --峰
            serfee_2 = '00000000',      --峰
            fee_2_sum = '00000000',     --峰sum
            fee_3 = '00000000',         --平
            serfee_3 = '00000000',      --平
            fee_3_sum = '00000000',     --平sum
            fee_4 = '00000000',         --谷
            serfee_4 = '00000000',      --谷
            fee_4_sum = '00000000',     --谷sum
            loss_rat = '00',            --计损比例
            time = {}
        })
        Gfeemodel = fskv.get('Gfeemodel')
    end

    gun_1 = fskv.get('gun_1')
    if gun_1 == nil then
        fskv.set("gun_1", {
            pile_id = pile_id,
            -- ordernumber = '00000000000000000000000000000000',
            ordernumber = '10002302130001012306011004209730',
            charge_onTime = '0852040A010617',
            charge_offTime = '00000000000000',
            id = '01',                     -- 枪号
            state = '02',                  -- 状态 00离线 01故障 02空闲 03充电 04已插枪未充电 05充电结束未拔枪
            toHome = '02',                 -- 归位 00否 01是 02未知
            linkBattery = '00',            -- 连接电池否 00否 01是
            outVol = '2000',               -- 输出 电压 小数点后1位
            outCurr = '0200',              -- 输出 电流 小数点后1位
            gunTemp = '00',                -- 枪线温度
            gunCode = '0000000000000000',  -- 枪线编码
            SOC = '00',                    -- 待机0 交流桩0
            batteryTemp = '00',            -- 电池组最高温度 待机0 交流桩0
            chargeTimeSum = '0000',        -- 充电时间 待机0 交流桩0
            remainTime = '0000',           -- 剩余时间 待机0 交流桩0
            chargeDegree = '00000000',     -- 充电度数 小数点后4位
            chargeLossDegree = '00000000', -- 充电计损度数 小数点后4位
            money = '00000000',            -- 已充金额 小数点后4位 待机0 （电费+服务费）*计损充电度数
            error = '0000'
        })
        gun_1 = fskv.get('gun_1')
    end
end)

--=============================================================

-- 处理未识别的网络消息
local function netCB(msg)
    log.info("未处理消息", msg[1], msg[2], msg[3], msg[4])
end

-- 统一联网函数
-- sys.taskInit(function()
--     -----------------------------
--     -- 统一联网函数, 可自行删减
--     ----------------------------
--     if wlan and wlan.connect then
--         -- wifi 联网, ESP32系列均支持, 要根据实际情况修改ssid和password!!
--         local ssid = "uiot"
--         local password = "123456"
--         log.info("wifi", ssid, password)
--         -- TODO 改成自动配网
--         wlan.init()
--         wlan.setMode(wlan.STATION) -- 默认也是这个模式,不调用也可以
--         wlan.connect(ssid, password, 1)
--     elseif mobile then
--         -- EC618系列, 如Air780E/Air600E/Air700E
--         -- mobile.simid(2) -- 自动切换SIM卡, 按需启用
--         -- 模块默认会自动联网, 无需额外的操作
--     elseif w5500 then
--         -- w5500 以太网
--         w5500.init(spi.HSPI_0, 24000000, pin.PC14, pin.PC01, pin.PC00)
--         w5500.config() --默认是DHCP模式
--         w5500.bind(socket.ETH0)
--     elseif socket then
--         -- 适配了socket库也OK, 就当1秒联网吧
--         sys.timerStart(sys.publish, 1000, "IP_READY")
--     else
--         -- 其他不认识的bsp, 循环提示一下吧
--         while 1 do
--             sys.wait(1000)
--             log.info("bsp", "本bsp可能未适配网络层, 请查证")
--         end
--     end
--     -- 默认都等到联网成功
--     sys.waitUntil("IP_READY")
--     sys.publish("net_ready")
-- end)

-- 上送下送task
local function sockettest()
    -- 等待联网
    sys.waitUntil("simidready")
    -- 开始正在的逻辑, 发起socket链接,等待数据/上报心跳
    taskName = "sc"
    topic = taskName .. "_txrx"
    txqueue = {}

    sysplus.taskInitEx(sockettask, taskName, netCB, taskName, txqueue, topic)
    sys.waitUntil('sysinit')
    while 1 do
        local result, tp, data = sys.waitUntil(topic, 10000)
        -- local result, tp, data = sys.waitUntil('heart', 10000)
        if not result then
            -- 等很久了,没数据上传/下发, 发个日期心跳包吧
            local heart = Frame_Send(sernum, crytoflag, '03', pile_id .. gun_1.id .. '00')
            -- table.insert(txqueue, heart)
            sys.publish(topic, "uplink", heart)
            log.info('heart', 'heartbeat', 'Req:', ReconnectReq, 'Vic:', ReconnectVic)
            -- sys.publish('heartcall03')
        elseif tp == "uplink" then
            -- 上行数据, 主动上报的数据,那就发送呀
            --sernum = sernum + 1
            table.insert(txqueue, data)
            sys_send(taskName, socket.EVENT, 0)
            local pr, len = string.toHex(data)
            log.info('send', '插入数据', pr)
        elseif tp == "downlink" then
            --local scit = {}
            local data_fix, error, sci = Frame_Recv(data)
            if error == false then
                log.info("socket", "收到下发的数据了", #data_fix.hexStr, data_fix.hexStr)
                log.info('frametype', data_fix.frametype, data_fix.dat)
                sys.publish('frametype', data_fix.frametype, data_fix.dat)

                -- if sci ~= '' then
                --     repeat
                --         local data_fix, error, sci = Frame_Recv(sci)
                --         sys.timerStart(function()
                --             log.info('frametype', data_fix.frametype, data_fix.dat)
                --             sys.publish('frametype', data_fix.frametype, data_fix.dat)
                --         end, 1000)
                --     until sci == ''
                -- end

                if sci ~= '' then
                    sys.timerStart(function()
                        log.info('frametype', 'SCIdata', sci:sub(11, 12), sci:sub(13, -9))
                        sys.publish('frametype', sci:sub(11, 12), sci:sub(13, -9))
                    end, 1000)
                end
            end
        end
    end
end

-- count
sys.timerLoopStart(function()
    print('test')
end, 1000)

-- 心跳处理
-- sys.taskInit(function()
--     while true do
--         local result = sys.waitUntil('heartcall03', 10000)
--         if result then
--             local result = sys.waitUntil('heartcall04', 11000)
--             if result == false then
--                 local login_str =  Frame_Send(sernum, crytoflag, '01', pile_id .. pile_type..pile_number..agreementV..procedureV..simid..Operators)
--                 log.info('heart', '2次未收到心跳应答重新登录')
--                 ReconnectReq = ReconnectReq + 1
--                 sys.publish(topic, "uplink", login_str)
--                 local result = socket.discon(netc)
--                 log.info('discon', '断连',result)
--             end
--         end
--     end
-- end)
-- updata

-- 上传实时监测数据 处理
sys.taskInit(function()
    sys.waitUntil('login')
    while true do
        -- local chargeon, ordernumber, charge_onTime = sys.waitUntil('chargeon', 300000)
        local chargeon = sys.waitUntil('chargeon', 15000)
        while chargeon do
            local chargeoff = sys.waitUntil('chargeoff', 15000)
            if chargeoff then
                local detail = Bill_Detail_Link(gun_1, Gfeemodel)
                local data = Frame_Send(sernum, crytoflag, '3f', detail)
                sys.publish(topic, "uplink", data)
                log.info('charge', '充电结束', '上传交易记录')
                sys.publish('chargeoffsucc')
                break
            else
                local detail = Up_Data_Link(gun_1)
                local data = Frame_Send(sernum, crytoflag, '13', detail)
                sys.publish(topic, "uplink", data)
                log.info('charge', '充电中', '上传实时监测数据')
            end
        end
        if chargeon == false then
            local detail = Up_Data_Link(gun_1)
            local data = Frame_Send(sernum, crytoflag, '13', detail)
            sys.publish(topic, "uplink", data)
            log.info('charge', '待机中', '上传实时监测数据')
        end
    end
end)
-- 接收处理
sys.taskInit(function()
    -- sys.waitUntil('readyrecv', 300000) --等待连接
    --sys.wait(3000)
    while true do
        local result, type, data = sys.waitUntil('frametype')
        if result then
            -- 登录验证
            if type == '02' then
                local result = data:sub(-2, -1)
                if result == '00' then
                    log.info('login', '--登录成功--')
                    sys.publish('login')
                    ReconnectVic = ReconnectVic + 1
                else
                    log.info('login', '--登录失败--')
                    sys.timerStart(function()
                        local data = Frame_Send(sernum, crytoflag, '01',
                            pile_id .. pile_type .. pile_number .. agreementV .. procedureV .. simid .. Operators)
                        sys.publish(topic, "uplink", data)
                    end, 2000)
                end
            end
            -- 心跳
            if type == '04' then
                log.info('heart', '--心跳应答成功--')
                -- sys.publish('heartcall04')
                -- sys.timerStart(function()
                --     local heart = Frame_Send(sernum, crytoflag, '03', pile_id .. gun_1.id .. '00')
                --     sys.publish(topic, "uplink", heart)
                --     sys.publish('heartcall03')
                -- end, 10000)
            end
            -- 验证模型
            if type == '06' then
                if data:sub(-2, -1) == '00' then
                    log.info('feemodel', '计费模型与云端一致')
                else
                    log.info('feemodel', '计费模型与云端不一致,尝试重新申请模型', 'now:',
                        Gfeemodel.feemodel_id, 'air:', data:sub(-6, -3))
                    sys.timerStart(function()
                        local msg09 = Frame_Send(sernum, crytoflag, '09', pile_id)
                        sys.publish(topic, "uplink", msg09)
                    end, 2000)
                end
            end
            -- 应答上传实时监测数据
            if type == '12' then

            end
            -- 应答 远程充电启动
            if type == '34' then
                -- local Ordernumber = data:sub(1, 32)
                gun_1.ordernumber = data:sub(1, 32)
                gun_1.charge_onTime = ConvertToCP56Time2a_Osdate()
                fskv.set('gun_1',gun_1)
                local data = Frame_Send(sernum, crytoflag, '33', gun_1.ordernumber .. pile_id .. gun_1.id .. '0100')
                sys.publish(topic, "uplink", data)
                log.info('charge', '远程充电启动')
                gun_1.state = '03'
                sys.publish('chargeon')
                sys.timerStart(function()
                    local detail = Up_Data_Link(gun_1)
                    local data = Frame_Send(sernum, crytoflag, '13', detail)
                    sys.publish(topic, "uplink", data)
                    log.info('charge', '启桩上传数据', '上传实时监测数据')
                end,1000)
            end
            -- 应答 远程充电停止
            if type == '36' then
                gun_1.charge_offTime = ConvertToCP56Time2a_Osdate()
                local data = Frame_Send(sernum, crytoflag, '35', pile_id .. gun_1.id .. '0100')
                sys.publish(topic, "uplink", data)
                log.info('charge', '远程充电停止')
                gun_1.state = '05'
                sys.publish('chargeoff')
                sys.timerStart(function()
                    local detail = Up_Data_Link(gun_1)
                    local data = Frame_Send(sernum, crytoflag, '13', detail)
                    sys.publish(topic, "uplink", data)
                    log.info('charge', '停桩上传数据', '上传实时监测数据')
                end,1000)

                local result = sys.waitUntil('chargeoffsucc', 2000)
                if not result then
                    local detail = Bill_Detail_Link(gun_1, Gfeemodel)
                    fskv.set('bill1',detail)
                    local data = Frame_Send(sernum, crytoflag, '3f', detail)
                    log.info('bill', 'frame', '直接上传交易记录')
                    sys.publish(topic, "uplink", data)
                end
            end
            -- 确认 交易记录
            if type == '40' then
                local ordernumber = data:sub(1, 32)
                if ordernumber == gun_1.ordernumber then
                    local result = data:sub(33, 34)
                    if result == '00' then
                        log.info('bill', '交易记录上传成功')
                    else
                        log.info('bill', '交易记录上传失败')
                        --  再发送
                    end
                else
                    log.info('bill', '流水号与当前不一致')
                end
            end
            -- 桩参数设置
            if type == '52' then
                local pile_id = data:sub(1, 14)
                local msg = data:sub(14, 15)
                local power = data:sub(15, 16)
                local data = Frame_Send(sernum, crytoflag, '51', pile_id .. '00')
                sys.publish(topic, "uplink", data)
                log.info('setting', '桩参数设置')
                -- 允许工作

                -- 最大允许功率
            end
            -- 应答 对时
            if type == '56' then --data = '10002302130001 B0B31C08110517'
                -- 解析CP56time2a格式数据
                local result, formattime = ParseCP56time2a(data:sub(15, 28))
                if result then log.info('time', 'CP56time2a', formattime) end
                local data = Frame_Send(sernum, crytoflag, '55', pile_id .. data:sub(8, 21))
                sys.publish(topic, "uplink", data)
            end
            -- 解析 计费模型
            -- 68（起始标志）0C（数据长度）0009（序列号域）00（加密标志）53（类型）32010200000001（桩编码）01（设置结果）C1A9（桢校验域）
            if type == '58' or type == '0A' then
                if type == '58' then
                    local data = Frame_Send(sernum, crytoflag, '57', pile_id .. '01')
                    sys.publish(topic, "uplink", data)
                end
                log.info('feemodel', '载入下发的计费模型设置')
                Gfeemodel = Model_Fix(data)
                Model_Log(Gfeemodel)
                print(Gfeemodel.feemodel_id)

                -- sys.timerStart(function ()
                --     local data = Frame_Send(sernum, crytoflag, '13', '000000000000000000000000000000001000230213000101040001020000200000000000000000000000000000001000000000000000100000000000')
                --     sys.publish(topic, "uplink", data)
                -- end,5000)
            end
            -- 应答 远程重启
            if type == '92' then
                local data = Frame_Send(sernum, crytoflag, '91', pile_id .. '01')
                sys.publish(topic, "uplink", data)
                sys.wait(5000)
                rtos.reboot()
            end
            -- 应答 二维码
            if type == '9C' then
                local gun_id = data:sub(1, 2)
                local data = Frame_Send(sernum, crytoflag, '9b', pile_id .. gun_id .. '01')
                sys.publish(topic, "uplink", data)
            end
        end
    end
end)
--底层task
function sockettask(d1Name, txqueue, rxtopic)
    -- 打印准备连接的服务器信息
    log.info("socket", host, port, is_udp and "UDP" or "TCP", is_tls and "TLS" or "RAW")

    -- 准备好所需要的接收缓冲区
    local rx_buff = zbuff.create(2048)
    netc = socket.create(nil, d1Name)
    socket.config(netc, nil, is_udp, is_tls, 30, 5, 3)
    -- socket.config(netc, nil, is_udp, is_tls)
    log.info("任务id", d1Name)

    --登录认证
    local login_str = Frame_Send(sernum, crytoflag, '01',
        pile_id .. pile_type .. pile_number .. agreementV .. procedureV .. simid .. Operators)
    while true do
        -- 连接服务器, 15秒超时
        log.info("socket", "开始连接服务器")
        local result = libnet.connect(d1Name, 15000, netc, host, port)
        if result then
            log.info("socket", "服务器连上了")
            sys.publish('sysinit')
            -- libnet.tx(d1Name, 5000, netc, login_str)
            --Send(login_str,txqueue,taskName)
            sys.publish(rxtopic, "uplink", login_str)
            ReconnectReq = ReconnectReq + 1
            -- sys.timerStart(function ()
            --     sys.publish(rxtopic, "uplink", login_str)
            -- end,28000)
            -- sys.timerStart(function()
            --     local heart = Frame_Send(sernum, crytoflag, '03', pile_id .. '0100')
            --     sys.publish(rxtopic, "uplink", heart)
            -- end, 1000)

            sys.timerStart(function()
                local msg05 = Frame_Send(sernum, crytoflag, '05', pile_id .. Gfeemodel.feemodel_id)
                sys.publish(rxtopic, "uplink", msg05)
            end, 3000)
        else
            log.info("socket", "服务器没连上了!!!")
        end
        while result do
            -- 连接成功之后, 先尝试接收
            -- log.info("socket", "调用rx接收数据")
            local succ, param = socket.rx(netc, rx_buff)
            if not succ then
                log.info("服务器断开了", succ, param, host, port)
                break
            end
            -- 如果服务器有下发数据, used()就必然大于0, 进行处理
            if rx_buff:used() > 0 then
                log.info("socket", "收到服务器数据，长度", rx_buff:used())
                local data = rx_buff:query()           -- 获取数据
                sys.publish(rxtopic, "downlink", data) -- 发布下行消息 与 数据
                rx_buff:del()
            end
            -- log.info("libnet", "调用wait开始等待消息")
            -- 等待事件, 例如: 服务器下发数据, 有数据准备上报, 服务器断开连接
            result, param, param2 = libnet.wait(d1Name, 30000, netc) -- result 判定是否联网 param 判定有无新网络事件
            -- sys.publish('heart')
            log.info("libnet", "wait", result, param, param2)
            if not result then
                -- 网络异常了, 那就断开了, 执行清理工作
                log.info("socket", "服务器断开了", result, param)
                break
            elseif #txqueue > 0 then
                -- 有待上报的数据,处理之
                while #txqueue > 0 do
                    local data = table.remove(txqueue, 1)
                    if not data then
                        break
                    end
                    result, param = libnet.tx(d1Name, 5000, netc, data)
                    log.info("libnet", "发送数据的结果", result, param)
                    if not result then
                        log.info("socket", "数据发送异常", result, param)
                        break
                    end
                end
            end
            -- 循环尾部, 继续下一轮循环
        end
        -- 能到这里, 要么服务器断开连接, 要么上报(tx)失败, 或者是主动退出
        libnet.close(d1Name, 0, netc)
        rtos.reboot()
        -- log.info(rtos.meminfo("sys"))
        -- sys.wait(20000) -- 这是重连时长, 自行调整
    end
end

local uartid = 1 -- 根据实际设备选取不同的uartid
--初始化
local result = uart.setup(
    uartid, --串口id
    115200, --波特率
    8,      --数据位
    1       --停止位
)
-- --循环发数据
sys.timerLoopStart(uart.write, 10000, uartid, "ready")
-- 收取数据会触发回调, 这里的"receive" 是固定值
uart.on(uartid, "receive", function(id, len)
    local s = ""
    repeat
        -- 如果是air302, len不可信, 传1024
        -- s = uart.read(id, 1024)
        s = uart.read(id, len)
        if #s > 0 then -- #s 是取字符串的长度
            -- 如果传输二进制/十六进制数据, 部分字符不可见, 不代表没收到
            -- 关于收发hex值,请查阅 https://doc.openluat.com/article/583
            --log.info("uart", "receive", id, #s, s)
            -- local data = Frame_Send(sernum,crytoflag,'13',pile_id..gun_1.id..'040001000000000000000000000000000000000000000000000000000000000000000000')
            if s == 'modellog' then
                Model_Log(Gfeemodel)
            elseif s:find('toself') ~= nil then
                log.info('toself', '--接收串口下发--')
                local result = s:gsub('toself', '')
                sys.publish(topic, "downlink", result) -- 发布下行消息 与 数据
            elseif s:find('updata') ~= nil then
                log.info('updata', '--数据上报--')
                local result = s:gsub('updata', '')
                -- local result = result:gsub('/', '')
                -- 状态 00离线 01故障 02空闲 03充电 04已插枪未充电 05充电结束未拔枪
                sys.publish(topic, "uplink", result) -- 发布下行消息 与 数据
            elseif s:find('stage') ~= nil then
                log.info('stage', '--stage上报--')
                local result = s:gsub('stage', '')
                -- local result = result:gsub('/', '')
                -- 状态 00离线 01故障 02空闲 03充电 04已插枪未充电 05充电结束未拔枪
                gun_1.state = result
            elseif s:find('param') ~= nil then
                log.info('param', '--param上报--')
                local result = s:gsub('param', '')
                local head, tail, ret1, ret2 = result:find('(.-)/(.-)/')
                if ret1 == 'vol' then
                    gun_1.outVol = ret2
                elseif ret1 == 'curr' then
                    gun_1.outCurr = ret2
                elseif ret1 == 'time' then
                    gun_1.chargeTimeSum = ret2
                elseif ret1 == 'degree' then
                    gun_1.chargeDegree = ret2
                elseif ret1 == 'money' then
                    gun_1.money = ret2
                end
                log.info('param', '--param--', ret1, ret2)
            elseif s:find('frdl') ~= nil then
                local result = s:gsub('frdl上报', '')
                local head, tail, ret1, ret2 = result:find('(.-)/(.-)/')
                log.info('serail_framedownload', 'frametype', ret1, ret2)
                sys.publish('frametype', ret1, ret2)
                -- elseif s == 'libnetclose' then
                --     log.info('closelibnet','serialtrigger')
                --     libnet.close('sc', 15000, netc)
            elseif s == 'gun1' then
                print('============================')
                for key, value in pairs(gun_1) do
                    print(key, value)
                end
                print('============================')
            else
                print('未识别的指令')
            end
            -- log.info("uart", "receive", id, #s, s:toHex())
        end
        if #s == len then
            break
        end
    until s == ""
end)
-- 并非所有设备都支持sent事件
-- uart.on(uartid, "sent", function(id)
--     log.info("uart", "sent", id)
-- end)
sys.taskInit(sockettest)

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
