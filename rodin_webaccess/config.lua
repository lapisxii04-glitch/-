Config = {}

Config.Debug = false -- Enable debug logs

Config.Locations = {
    {
        name = "test1", -- Display name
        blip = { enable = true, sprite = 587827268, }, -- If player has no access (based on requiredJobs), the blip will not be shown
        model = "p_bookcasenb01x", -- false or model name
        coords = { -- Multiple positions supported
            vector4(749.3200073242188, 1828.6700439453125, 237.63999938964844, 31),
        }, -- x, y, z, yaw
        requiredJobs = { ["admin"] = 0, ["police"] = 2 }, --{ ["admin"] = 0, ["police"] = 2 }, or false,
        links = { -- label = menu text / url = link to open
            { label = "User Manual", url = "https://example.com/user-manual" },
            { label = "Video Manual", url = "https://example.com/video-manual" },
        }
    },
    {
        name = "PD Manual",
        blip = { enable = true, sprite = 587827268, },
        model = "p_book08x",
        coords = {
            vector4(-762.52001953125, -1267.6199951171875, 43.84400177001953, -139.99998474121094), -- bw
            vector4(-276.739990234375, 807.239990234375, 119.18000030517578, -34), -- vt
        },
        requiredJobs = {["police"] = 0},
        links = {
            { label = "Calculation Sheet", url = "https://example.com/calculation-sheet" },
            { label = "test", url = "https://example.com/test" },
        }
    },
    {
        name = "Catalog",
        blip = { enable = true, sprite = 587827268, },
        model = "s_rippablebook01x",
        coords = {
            vector4(-1816.76904296875, -422.9707336425781, 159.82107543945312, 154.39669799804688),
        },
        requiredJobs = false,
        links = {
            { label = "Furniture List", url = "https://example.com/furniture-list" },
        }
    },
    {
        name = "Menu",
        blip = { enable = false, sprite = 587827268, },
        model = "s_bla_menuclipboard01",
        coords = {
            vector4(-760.6392, -1324.3820, 43.7925, 0),
        },
        requiredJobs = false,
        links = {
            { label = "Menu", url = "https://example.com/menu-bw-raf" },
        }
    },
}
