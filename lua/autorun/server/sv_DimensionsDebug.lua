-- Temp: allow dimension hopping using commands
concommand.Add("dim_goto",function(ply,cmd,args)
    ply:SetDimension(tonumber(args[1]))
    print("Teleported ",ply," to dimension ",ply:GetDimension())
end)
concommand.Add("dim_send",function(ply,cmd,args)
    if not IsValid(ply:GetEyeTrace().Entity) then return end
    ply:GetEyeTrace().Entity:SetDimension(tonumber(args[1]))
    print("Teleported ",ply:GetEyeTrace().Entity," to dimension ",ply:GetEyeTrace().Entity:GetDimension())
end)