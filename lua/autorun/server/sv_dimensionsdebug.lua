-- Temp: allow dimension hopping using commands
concommand.Add("dim_goto",function(ply,cmd,args)
    ply:SetDimension(args[1])
end)
concommand.Add("dim_send",function(ply,cmd,args)
    if not IsValid(ply:GetEyeTrace().Entity) then return end
    ply:GetEyeTrace().Entity:SetDimension(args[1])
end)