
local login_const = require "login_api.login_const"

local function inner_auth(openId, userData)
    return true
end

local function debug_auth(openId, userData)
    -- TODO:
    return false
end

local function weichat_auth(openId, userData)
    local access_token = userData
    -- NOTICE: umeng uid is unionid, not openid if unionid exist.
    local result, content = skynet.call('.webclient', "lua", "request", "https://api.weixin.qq.com/sns/userinfo", {openid=openId, access_token=access_token, lang="zh_CN"})
    if not result then
        ERROR("request weixin network error")
        return false
    end

    local content = json.decode(content)
    if content.errcode then
        DEBUG("weichat_auth:", result, inspect(content))
        return false
    end
    return true, content.openid
end


local sdk = login_const.sdk
local auth_handler = {
    [sdk.debug] = debug_auth,
    [sdk.inner] = inner_auth,
    [sdk.weichat] = weichat_auth,
}

return function(openId, sdk, userData)
    local fc = auth_handler[sdk]
    return fc(openId, userData)
end