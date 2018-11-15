
local settings = {}

settings.word_crab_file = 'data/word_crab/words.txt'

-- 登陆认证服
settings.login_conf = {
    console_port          = 15010,
    login_port            = 15110,   --(暴露) 登陆认证端口
    login_slave_cout      = 8,      -- 登陆认证代理个数
}

-- 中心服
settings.center_conf = {
    console_port           = 15011,
    nodeName               = "center",
}

settings.lobbys = {
        ['1'] = {
            -- 网络配置
            nodeName     = "lobby1",  -- 每个lobby名字必须唯一
            console_port  = 15012, -- 执行关服操作 game.sh 中 EXIT_PORT 也要保持一致

            gate_host     = '127.0.0.1', -- 需要手动修改
            gate_port     = 15112, 		 --(暴露 网关端口 TCP)
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
        },

        dbproxy = "mongodb",
        mongodb_maxinst = 8,
        mongodb_cnf = {
            host = "127.0.0.1",
            port = "27017",
        },
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
        
        dbproxy = "mongodb",

        mongodb_maxinst = 8,
        mongodb_cnf = {
            host = "127.0.0.1",
            port = "27017",
        },
    },

}

return settings
