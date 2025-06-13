_onSpot = false
isMinigame = false
_SafeCrackingStates = "Setup"

RegisterCommand("createSafe",function()
	local ss = createSafe({math.random(0,99), math.random(0,99), math.random(0,99)})
	print(ss)
end, false)

local CancelPrompt, OpenPrompt, RotatePrompt, SlowPrompt
local Prompts = GetRandomIntInRange(0, 0xffffff)

Citizen.CreateThread(function()
	Citizen.InvokeNative(0xD9130842D7226045, 'Mud5_Sounds', 0)

    local str = 'Cancel'
    CancelPrompt = PromptRegisterBegin()
    PromptSetControlAction(CancelPrompt, 0x156F7119)	-- ESC
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CancelPrompt, str)
    PromptSetEnabled(CancelPrompt, true)
    PromptSetVisible(CancelPrompt, true)
    PromptSetStandardMode(CancelPrompt, 1000)
    PromptSetGroup(CancelPrompt, Prompts)
    PromptRegisterEnd(CancelPrompt)

	local str = 'Open'
    OpenPrompt = PromptRegisterBegin()
    PromptSetControlAction(OpenPrompt, 0x2CD5343E)	-- W
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(OpenPrompt, str)
    PromptSetEnabled(OpenPrompt, true)
    PromptSetVisible(OpenPrompt, true)
    PromptSetStandardMode(OpenPrompt, 1000)
    PromptSetGroup(OpenPrompt, Prompts)
    PromptRegisterEnd(OpenPrompt)

	local str = 'Rotate'
    RotatePrompt = PromptRegisterBegin()
    PromptSetControlAction(RotatePrompt, 0x7065027D)	-- A
	PromptSetControlAction(RotatePrompt, 0xB4E465B4)	-- D
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(RotatePrompt, str)
    PromptSetEnabled(RotatePrompt, true)
    PromptSetVisible(RotatePrompt, true)
    PromptSetStandardMode(RotatePrompt, 1000)
    PromptSetGroup(RotatePrompt, Prompts)
    PromptRegisterEnd(RotatePrompt)

	local str = 'Slow (Hold)'
    SlowPrompt = PromptRegisterBegin()
    PromptSetControlAction(SlowPrompt, 0x8FFC75D6)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(SlowPrompt, str)
    PromptSetEnabled(SlowPrompt, true)
    PromptSetVisible(SlowPrompt, true)
    PromptSetStandardMode(SlowPrompt, 1000)
    PromptSetGroup(SlowPrompt, Prompts)
    PromptRegisterEnd(SlowPrompt)
end)

local function DrawText(text, x, y, fontscale, fontsize, r, g, b, alpha, textcentred, shadow)
    local str = CreateVarString(10, "LITERAL_STRING", text)
    SetTextScale(fontscale, fontsize)
    SetTextColor(r, g, b, alpha)
    SetTextCentre(textcentred)
    if shadow then 
        SetTextDropshadow(1, 0, 0, 255)
    end
    SetTextFontForCurrentCommand(1)
    DisplayText(str, x, y)
end

function createSafe(combination)
	local res
	isMinigame = not isMinigame
	RequestStreamedTextureDict("qadr_safe_cracking",false)
	RequestStreamedTextureDict("ui_startup_textures",false)
	if isMinigame then
		if not combination then
			combination = {math.random(0,99)}
		end
		InitializeSafe(combination)
		while isMinigame do
			--playFx("mini@safe_cracking","idle_base")
			DrawSprites(true)
			res = RunMiniGame()

			local label  = CreateVarString(10, 'LITERAL_STRING', 'Break Safe')
			PromptSetActiveGroupThisFrame(Prompts, label)
			DrawText(_requiredDialRotationDirection, 0.5, 0.9, 0.7, 0.7, 255, 255, 255, 255, true, true)
			if res == true then
				return res
			elseif res == false then
				return res
			end

			Wait(0)
		end
	end
end

function InitializeSafe(safeCombination)
	_initDialRotationDirection = "Clockwise"
	_safeCombination = safeCombination
	RelockSafe()
	SetSafeDialStartNumber()
end

function DrawTexture(textureStreamed,textureName,x, y, width, height,rotation,r, g, b, a, p11)
    if not HasStreamedTextureDictLoaded(textureStreamed) then
       RequestStreamedTextureDict(textureStreamed, false);
    else
        DrawSprite(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11);
    end
end

function DrawSprites(drawLocks)
	local textureDict = "qadr_safe_cracking"
	local _aspectRatio = 16/9 --GetAspectRatio(true)

	DrawTexture("des_safe_sml_l_fail+hi","p_door_val_bankvault_small_ab",0.8,0.5,0.3,_aspectRatio*0.3,0,250,250,250,185)
	DrawTexture(textureDict,"Dial_BG",0.8,0.5,0.2,_aspectRatio*0.2,0,255,255,255,255)
	DrawTexture(textureDict,"Dial",0.8,0.5,0.2,_aspectRatio*0.2,SafeDialRotation,255,255,255,255)

	if not drawLocks then
		return
	end

	local xPos = 0.933
	local yPos = 0.43
	local _kilittexturedic = "elements_stamps_icons"
	for _,lockActive in pairs(_safeLockStatus) do
		local lockString
		if lockActive then
			lockString = "stamp_locked_rank"
		else
			lockString = "stamp_unlocked_rank"
		end

		DrawTexture(_kilittexturedic,lockString,xPos,yPos,0.025,_aspectRatio*0.025,0,231,194,81,255)
		yPos = yPos + 0.05
	end
end

function RunMiniGame()
	if _SafeCrackingStates == "Setup" then
		_SafeCrackingStates = "Cracking"
	elseif _SafeCrackingStates == "Cracking" then
		local isDead = GetEntityHealth(PlayerPedId()) <= 101
		if isDead then
			EndMiniGame(false)
			return false
		end

		if IsControlJustPressed(0,0x156F7119) then
			EndMiniGame(false)
			return false
		end

		if IsControlJustPressed(0,0x2CD5343E) then
			if _onSpot then
				ReleaseCurrentPin()
				_onSpot = false
				if IsSafeUnlocked() then
					EndMiniGame(true,false)
					return true
				end
			else
				EndMiniGame(false)
				return false
			end
 		end

		HandleSafeDialMovement()

		local incorrectMovement = _currentLockNum ~= 0 and _requiredDialRotationDirection ~= "Idle" and _currentDialRotationDirection ~= "Idle" and _currentDialRotationDirection ~= _requiredDialRotationDirection

		if not incorrectMovement then
			local currentDialNumber = GetCurrentSafeDialNumber(SafeDialRotation)
			local correctMovement = _requiredDialRotationDirection ~= "Idle" and (_currentDialRotationDirection == _requiredDialRotationDirection or _lastDialRotationDirection == _requiredDialRotationDirection)  
			if correctMovement then
				local pinUnlocked = _safeLockStatus[_currentLockNum] and currentDialNumber == _safeCombination[_currentLockNum]
				if pinUnlocked and not _onSpot then
					sescal("Mud5_Sounds","Small_Safe_Tumbler")
					_onSpot = true
				end
			end
		elseif incorrectMovement then
			_onSpot = false
		end
	end
end

function HandleSafeDialMovement()
	local isShiftHeld = (IsControlPressed(0, 0x8FFC75D6) or IsControlPressed(0, 0xD9D0E1C0)) and true or false
	if IsControlPressed(0,0x7065027D) then
		RotateSafeDial("Anticlockwise", isShiftHeld)
		--mini_games@safecrack@base: dial_turn_right_stage_00
	elseif IsControlPressed(0,0xB4E465B4) then
		RotateSafeDial("Clockwise", isShiftHeld)
	else
		RotateSafeDial("Idle", nil)
	end
end

function RotateSafeDial(rotationDirection, slow)
	if rotationDirection == "Anticlockwise" or rotationDirection == "Clockwise" then
		local multiplier
		local rotationPerNumber = 1.0
		if slow then
			rotationPerNumber = 0.1
		end
		if rotationDirection == "Anticlockwise" then
			multiplier = 1
		elseif rotationDirection == "Clockwise" then
			multiplier = -1
		end

		local rotationChange = multiplier * rotationPerNumber
		local SafeDialRotation_old = SafeDialRotation
		SafeDialRotation = SafeDialRotation + rotationChange
		if SafeDialRotation > 360 then
			SafeDialRotation = SafeDialRotation - 360
		elseif SafeDialRotation < 0 then
			SafeDialRotation = SafeDialRotation + 360
		end
		if math.abs(math.floor(SafeDialRotation_old) - math.floor(SafeDialRotation)) == 1 then
			sescal("Mud5_Sounds", "Dial_Turn_Single")
		end

	end

	_currentDialRotationDirection = rotationDirection
	_lastDialRotationDirection = rotationDirection
end

function SetSafeDialStartNumber()
	local dialStartNumber = math.random(0,100)
	SafeDialRotation = 3.6 * dialStartNumber
end

function RelockSafe()
	if not _safeCombination then
		return
	end
    
	_safeLockStatus = InitSafeLocks()
	_currentLockNum = 1
	_requiredDialRotationDirection = _initDialRotationDirection
	_onSpot = false

	for i = 1,#_safeCombination do
		_safeLockStatus[i] = true
	end
end

function InitSafeLocks()
	if not _safeCombination then
		return
	end
    
	local locks = {}
 	for i = 1,#_safeCombination do
		table.insert(locks,true)
	end

	return locks
end

function GetCurrentSafeDialNumber(currentDialAngle)
	local number = math.floor(100*(currentDialAngle/360))
	if number > 0 then
		number = 100 - number
	end

	return math.abs(number)
end

function ReleaseCurrentPin()
	local currentDialNumber = GetCurrentSafeDialNumber(SafeDialRotation)
	local pinUnlocked = _safeLockStatus[_currentLockNum] and currentDialNumber == _safeCombination[_currentLockNum]
	if not pinUnlocked then return end
	_safeLockStatus[_currentLockNum] = false
	_currentLockNum = _currentLockNum + 1
	if _requiredDialRotationDirection == "Anticlockwise" then
		_requiredDialRotationDirection = "Clockwise"
	else
		_requiredDialRotationDirection = "Anticlockwise"
	end
	sescal("Mud5_Sounds","Small_Safe_Tumbler")
end

function IsSafeUnlocked()
	return _safeLockStatus[_currentLockNum] == nil
end

function EndMiniGame(safeUnlocked)
	if safeUnlocked then
		sescal("Mud5_Sounds","Small_Safe_Unlock")

		--mini_games@safecrack@base: open_lt
		Citizen.CreateThread(function()
			ClearPedTasks(PlayerPedId())
		end)	
	else
		sescal("Mud5_Sounds","Small_Safe_Unlock")

		Citizen.CreateThread(function()
			ClearPedTasks(PlayerPedId())
		end)	
	end
	isMinigame = false
	SafeCrackingStates = "Setup"
end

function playFx(dict,anim)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Wait(10)
	end

	TaskPlayAnim(PlayerPedId(),dict,anim,3.0,3.0,-1,1,0,0,0,0)
end

exports("createSafe",createSafe)