{
    "dn": "CN=Project_462000008,OU=OKM,OU=LUMI,OU=External,OU=Projects,ou=idm,dc=csc,dc=fi", 
    "name": "project_462000008", 
    "gid": 462000008, 
    "prjnum": 462000008, 
    "scope": "lumi-okm", 
    "is_open": true, 
    "is_personal": false, 
    "title": "LUST Lumi user support", 
    "billing": {
        "cpu_hours": {
            "alloc": 1000000, 
            "used": 568192, 
            "remaining": 431808
        }, 
        "gpu_hours": {
            "alloc": 500000, 
            "used": 2563, 
            "remaining": 497437
        }, 
        "qpu_secs": {
            "alloc": 0, 
            "used": 0, 
            "remaining": 0
        }, 
        "storage_hours": {
            "alloc": 20000, 
            "used": 10942, 
            "remaining": 9058
        }
    }, 
    "ptypes": ["lumi-okm", "development"], 
    "kind": "compute", 
    "members": {
        "kurtlust": {
            "active": true
        }, 
        "orianlouant": {
            "active": true
        }, 
        "andersmart": {
            "active": true
        }, 
        "abdulaza": {
            "active": true
        }, 
        "thomasrob": {
            "active": true
        }, 
        "rafaelsarmiento": {
            "active": true
        }, 
        "janvicherek": {
            "active": true
        }, 
        "renejacobsen": {
            "active": true
        }, 
        "peterlarsson": {
            "active": true
        }, 
        "maciszpin": {
            "active": true
        }, 
        "nortamoh": {
            "active": true
        }, 
        "dietzej": {
            "active": true
        }, 
        "oryemman": {
            "active": true
        }, 
        "schouoxvig": {
            "active": true
        }, 
        "annevomm": {
            "active": true
        }, 
        "reimanhe": {
            "active": false
        }, 
        "heidirei": {
            "active": true
        }, 
        "tiksmihk2": {
            "active": true
        }, 
        "tella": {
            "active": false
        }, 
        "kotilas": {
            "active": true
        }, 
        "taskine1": {
            "active": false
        }, 
        "ssalonen": {
            "active": true
        }, 
        "jfagerho": {
            "active": true
        }
    }, 
    "has_active_members": true, 
    "enabled_partitions": ["debug", "dev-g", "eap", "interactive", "largemem", "small", "small-g", "standard", "standard-g", "lumid"],
    "organization": "lumi", 
    "parent_account": "lumi", 
    "valid_compute_project": true, 
    "storage_quotas": {
        "changes_pending": false, 
        "directories": {
            "projappl": {
                "block_quota_used": 798348288, 
                "block_quota_soft": 10737418240, 
                "block_quota_hard": 10738466816, 
                "inode_quota_used": 5265353, 
                "inode_quota_soft": 50000000, 
                "inode_quota_hard": 50001000
            }, 
            "scratch": {
                "block_quota_used": 559834340, 
                "block_quota_soft": 53687091200, 
                "block_quota_hard": 53688139776, 
                "inode_quota_used": 1097579, 
                "inode_quota_soft": 2000000, 
                "inode_quota_hard": 2001000
            }, 
            "flash": {
                "block_quota_used": 57700872, 
                "block_quota_soft": 2147483648, 
                "block_quota_hard": 2148532224, 
                "inode_quota_used": 43333, 
                "inode_quota_soft": 1000000, 
                "inode_quota_hard": 1001000
            }
        }
    },
    "partition_access": {
        "debug": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        }, 
        "dev-g": {
            "allowed": true, 
            "required_bu": ["gpu_hours"]
        }, 
        "eap": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        }, 
        "interactive": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        }, 
        "largemem": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        }, 
        "small": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        }, 
        "small-g": {
            "allowed": true, 
            "required_bu": ["gpu_hours"]
        }, 
        "standard": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        },
        "standard-g": {
            "allowed": true, 
            "required_bu": ["gpu_hours"]
        }, 
        "lumid": {
            "allowed": true, 
            "required_bu": ["cpu_hours"]
        }
    }
}