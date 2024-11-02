MagePortals = {}
MagePortals.portals = {
    { name = "法师传送门：铁炉堡", mapID = 87, x = 0.25, y = 0.08 },
    { name = "法师传送门：暴风城", mapID = 84, x = 0.49, y = 0.86 },
    { name = "法师传送门：达纳苏斯", mapID = 89, x = 0.43, y = 0.78 },
    { name = "法师传送门：埃索达", mapID = 103, x = 0.47, y = 0.63 },
    { name = "法师传送门：塞拉摩", mapID = 70, x = 0.64, y = 0.47 },
    { name = "法师传送门：锦绣谷", mapID = 1530, x = 0.56, y = 0.44 },
    { name = "法师传送门：暴风之盾", mapID = 622, x = 0.34, y = 0.63 },
    { name = "法师传送门：伯拉勒斯", mapID = 1161, x = 0.68, y = 0.16 },
    { name = "法师传送门：沙塔斯", mapID = 111, x = 0.56, y = 0.48 },
    { name = "法师传送门：达拉然（诺森德）", mapID = 125, x = 0.55, y = 0.46 },
    { name = "法师传送门：托尔巴拉德", mapID = 244, x = 0.54, y = 0.58 },
    { name = "法师传送门：远古达拉然巨坑", mapID = 25, x = 0.32, y = 0.36 },
    { name = "法师传送门：达拉然（破碎群岛）", mapID = 627, x = 0.57, y = 0.45 },
    { name = "法师传送门：奥利波斯", mapID = 1670, x = 0.59, y = 0.38 },
    { name = "法师传送门：瓦德拉肯", mapID = 2112, x = 0.48, y = 0.64 },


    { name = "时光之穴 - 暴风城传送", mapID = 75, x = 0.5594, y = 0.5350 },
    { name = "托尔巴拉德 - 暴风城郊外", mapID = 244, x = 0.7470, y = 0.1830 },
    { name = "深岩之洲 - 暴风城郊外", mapID = 207, x = 0.5000, y = 0.5300 },
    { name = "暮光高地 - 暴风城郊外", mapID = 241, x = 0.6067, y = 0.2622 },
    { name = "海加尔 - 暴风城郊外", mapID = 198, x = 0.6207, y = 0.2100 },
    { name = "奥丹姆 - 暴风城郊外", mapID = 249, x = 0.5490, y = 0.3270 },


}

-- 添加地图标记
function MagePortals:CreatePortalMarkers()
    if TomTom then
        for _, portal in ipairs(self.portals) do
            TomTom:AddWaypoint(portal.mapID, portal.x, portal.y, {
                title = portal.name,
                persistent = true,
                minimap = true,
                world = true,
            })
        end
    else
        print("请安装TomTom插件以显示法师传送门位置。")
    end
end

-- /run MagePortals:CreatePortalMarkers()
-- /run TomTom:ClearAllWaypoints()
