local module = {
	["A"] = {
		["DoseAlarm"] = 25,
		["DoseRateAlarm"] = 10,
		["DoseLimit"] = 100,
		["DoseRateLimit"] = 10,
		["Coverage"] = {"A"}
	},
	["B"] = {
		["DoseAlarm"] = 25,
		["DoseRateAlarm"] = 10,
		["DoseLimit"] = 100,
		["DoseRateLimit"] = 50,
		["Coverage"] = {"B"}
	},
	["C"] = {
		["DoseAlarm"] = 25,
		["DoseRateAlarm"] = 10,
		["DoseLimit"] = 100,
		["DoseRateLimit"] = 50,
		["Coverage"] = {"C"}
	},
	["D"] = {
		["DoseAlarm"] = 100,
		["DoseRateAlarm"] = 20,
		["DoseLimit"] = 250,
		["DoseRateLimit"] = 50,
		["Coverage"] = {"D"}
	},
	["E"] = {
		["DoseAlarm"] = 500,
		["DoseRateAlarm"] = 100,
		["DoseLimit"] = 1000,
		["DoseRateLimit"] = 250,
		["Coverage"] = {"D", "E"}
	},
	["F"] = {
		["DoseAlarm"] = 1000,
		["DoseRateAlarm"] = 600,
		["DoseLimit"] = 2500,
		["DoseRateLimit"] = 1000,
		["Coverage"] = {"D", "E", "F"}
	}
}

return module