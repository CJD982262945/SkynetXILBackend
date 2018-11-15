
local errorcode = {}

function errmsg(ec)
    if not ec then
        return "nil"
    end
    return errorcode[ec].desc
end

local function add(err)
    assert(errorcode[err.code] == nil, string.format("have the same error code[%x], msg[%s]", err.code, err.message))
    errorcode[err.code] = {desc = err.desc }

    return err.code
end

SYSTEM_ERROR = {
    ok                          = add{code = 0, desc = "请求成功"},
    success                     = add{code = 100, desc = "请求成功"},
    invalid_param               = add{code = 101, desc = "非法参数"},
    unknow                      = add{code = 102, desc = "未知错误"},
    argument                    = add{code = 103, desc = "参数错误"},
    invalid_action              = add{code = 104, desc = "非法操作"},
    player_not_found            = add{code = 105, desc = "没有此玩家"},
}



return errorcode
