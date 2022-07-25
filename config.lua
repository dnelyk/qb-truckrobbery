Config = Config or {}

--- Cooldown / Timers
Config.Cooldown = 600 --- 10 Minutes. Insert time in seconds.


-- Hack Config
Config.HackType = "memory" -- Either "laptop" or "memory" as of Version 1.1 ---- "laptop" requires https://github.com/Jesper-Hustad/NoPixel-minigame/tree/main/fivem-script/hacking
Config.HackItem = "trojan_usb"  -- The actual item used to start the hack.
Config.NoItemMessage = "You do not have login credentials." -- Message when player doesnt have the item needed.

-- Prog Bar
Config.ProgressMessage = "Inserting Trojan USB..." -- Progress bar message when beginning hack.
Config.ProgressTime = 6500 -- MS, 6.5s

-- Rewards 
Config.BagAmount = math.random(1,3) -- Amount of bags you can get from the truck
Config.BagWorth = math.random(10052, 14628) -- Random Cash amount that markedbills are worth
Config.RareItem = 'security_card_01' -- Rare item from truck (10% chance of this item)


-- Email
Config.EmailSubject = "Gruppe Sechs Security Truck" --- The Subject of the Email
Config.EmailMessage = "I have marked the location on your GPS." -- What it says in the email
Config.Sender = "The Boss"  -- The sender on the email.

-- Notifications / Police
Config.UnavailableNotification = "There are no trucks in service." -- When there is an active cooldown, this message pops up.
Config.FailureNotification = "You failed the hack." -- When the player fails the minigame hack.
Config.HackSuccessNotification = "The location has been marked on your GPS." -- The notification when successfully hacked.
Config.KillGuardsNotification = "Get rid of the guards before you place the bomb." -- When the player gets close, if will send this message.
Config.BombedSuccessNotification = "You can start collecting cash." -- When the player successfully places the bomb on the truck.
Config.PositionErrorNotification = "I can't place the charge from here." -- If the player is in the water while placing the charge.
Config.VehicleNotEmptyNotification = "The vehicle must be empty to place the load." -- If the player trys to place charge, while guards are still in vehicle.
Config.VehicleMovingNotification = "You cant rob a vehicle that is moving." -- If the player trys to place charge, while vehicle is moving.
Config.BombCooldownNotification = "You have already placed the charge." -- If the player trys to place charge again.
Config.CashGrabNotification = "You are packing cash into a bag" -- When player begins grabbing cash from truck.
Config.CashCooldownNotification = "The security truck is empty." -- This is after the player has already grabbed cash, and trys to grab it again.

Config.PoliceAlertMessage = "10-90: Armored Truck Robbery" -- Message police recieve

-- Target Prompts / Icons

Config.BombPrompt = "Blow the Back Door" -- Prompt for target eye for the "bomb"
Config.BombIcon = 'fas fa-bomb' -- Prompt for target eye for Bomb

Config.CashPrompt = "Grab the Cash" -- Prompt for target eye for the "Cash"
Config.CashIcon = 'fas fa-dollar-sign'  -- Icon for the target eye for Cash

