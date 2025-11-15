hook.Add("OnPlayerChat", "make players very lonely across dimensions", function( index, name, text, type )
    if(ply:GetDimension() ~= LocalPlayer():GetDimension()) then return false end

    --probably add a way for players to talk cross dimension anyway, but dont make it default :3
end)