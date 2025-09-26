function sescal(dict,ses)
    local soundset_ref = dict or "Mud5_Sounds"
    local soundset_name = ses or  "Small_Safe_Unlock"
    if soundset_ref == 0 or Citizen.InvokeNative(0xD9130842D7226045 ,soundset_ref,0) then
        local ped = PlayerPedId()
        local ped_coords = GetEntityCoords(ped)
        Citizen.InvokeNative(0x6FB1DA3CA9DA7D90, soundset_name, PlayerPedId(), soundset_ref, true, 0, 0)  -- PLAY_SOUND_FROM_ENTITY
    end
end