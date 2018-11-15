
local settings = {}

settings.word_crab_file = 'data/word_crab/words.txt'

-- 登陆认证服
settings.login_conf = {
    console_port          = 9010,
    login_port            = 9110,   --(暴露) 登陆认证端口
    login_slave_cout      = 4,      -- 登陆认证代理个数
}

-- 中心服
settings.center_conf = {
    console_port           = 9011,
    nodeName               = "center",
}

settings.lobbys = {
        '1' = {
            -- 网络配置
            nodeName     = "lobby1",  -- 每个lobby名字必须唯一
            console_port  = 9012, -- 执行关服操作 server_dependency 中也要保持一致

            gate_host     = '127.0.0.1', -- 需要手动修改
            gate_port     = 9112, 		 --(暴露 网关端口 TCP)
            max_client    = 4000,
        },
    }


--db 配置
settings.db_cnf = {
    login = {
        redis_maxinst = 1,
        redis_cnf = {
            host = "127.0.0.1", 
            port = 16379,
            db = 0,
        }
    },

    center = {
        redis_maxinst = 1,
        redis_cnf = {
            host = "127.0.0.1", 
            port = 16379, 
            db = 0,
        }
    },

    lobby1 = {
        redis_maxinst = 4,
        redis_cnf = {
            host = "127.0.0.1", 
            port = 16379, 
            db = 0, 
        },
        
        dbproxy = "mongodb",-- "mongodb" "mysql"

        mongodb_maxinst = 8,
        mongodb_cnf = {
            host = "127.0.0.1",
        },
    },

}

return settings
